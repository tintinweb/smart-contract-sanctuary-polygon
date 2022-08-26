// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AppStorage, Player, Rarity} from "../libraries/LibAppStorage.sol";
import {Modifiers} from "../libraries/Modifiers.sol";
import "../libraries/LibLootbox.sol";

contract PlayerFacet is Modifiers {
    event LevelUpEvent(address player);

    struct PlayerInfo {
        address id;
        uint createdAt;
        uint256[] balances;
    }

    /// @notice Query all details relating to a player
    /// @dev This function throws for queries about the zero address and non-existing players.
    /// @param playerAddress The player to query
    /// @return _player The player's details
    function player(address playerAddress) public view playerExists(playerAddress) returns (PlayerInfo memory _player) {
        _player.id = playerAddress;
        _player.createdAt = s.players[playerAddress].createdAt;
        _player.balances = new uint256[](s.rarities.length + 1);
        for (uint i = 0; i < s.rarities.length + 1; i++) {
            _player.balances[i] = s._balances[i][playerAddress];
        }
        return _player;
    }

    function playerTotalMintedLootboxes(address playerAddress) public view returns (uint256[] memory) {
        return s.totalMintedLoootboxesByPlayer[playerAddress];
    }

    function playerTotalOpenedLootboxes(address playerAddress) public view returns (uint256[] memory) {
        return s.totalOpenedLoootboxesByPlayer[playerAddress];
    }

    function playerTotalMaticEarned(address playerAddress) public view returns (uint256) {
        return s.totalMaticEarnedByPlayer[playerAddress];
    }

    function playerTotalGuildTokenEarned(address playerAddress) public view returns (uint256) {
        return s.totalGuildTokenEarnedByPlayer[playerAddress];
    }

    /// @notice Add a player
    /// @dev This function throws for queries about the zero address and already existing players.
    /// @param playerAddress Address of the player to add
    function addPlayer(address playerAddress) external onlyGuildAdminOrGallion playerNotExists(playerAddress) {
        s.players[playerAddress] = Player(block.timestamp, 0, 0);
        s.totalMintedLoootboxesByPlayer[playerAddress] = new uint256[](s.rarities.length + 1);
        s.totalOpenedLoootboxesByPlayer[playerAddress] = new uint256[](s.rarities.length + 1);
        s.nPlayers++;
    }

    /// @notice Level-up a player
    /// @dev This function throws for queries about the zero address and non-existing players.
    /// @param playerAddress Address of the player to level-up
    function levelUp(address playerAddress) external onlyGuildAdminOrGallion playerExists(playerAddress) {
        LibLootbox.awardLevelUpLootbox(playerAddress);
    }

    /// @notice Remove a player
    /// @dev This function throws for queries about the zero address and non-existing players.
    /// @param playerAddress Address of the player to remove
    function removePlayer(address playerAddress) external onlyGuildAdminOrGallion playerExists(playerAddress) {
        delete s.players[playerAddress];
        s.nPlayers--;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LibMeta} from "./LibMeta.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct AppStorage {
    bytes32 domainSeparator;
    address gallionLabs;
    address guildMainWallet;
    uint256 guildTokenId; // Guild token id (ERC1155)
    Rarity[] rarities;
    mapping(Rarity => uint256) lootboxIds; // Lootbox id by rarity (ERC1155)
    mapping(uint256 => Rarity) lootboxRarity; // Lootbox rarity by id (ERC1155)
    mapping(uint256 => mapping(address => uint256)) _balances; // Tokens balances (ERC1155)
    mapping(address => uint256) investments;
    mapping(Rarity => uint256) guildTokensByLootbox; // Guild tokens by lootbox rarity (ERC1155)
    mapping(address => LootboxContent) lastLootboxContents; // Last lootbox contents by player
    mapping(address => uint256[]) totalMintedLoootboxesByPlayer; // Total minted lootboxes by rarity
    mapping(address => uint256[]) totalOpenedLoootboxesByPlayer; // Total opened lootboxes by rarity
    mapping(address => uint256) totalMaticEarnedByPlayer; // Total Matic earned by player
    mapping(address => uint256) totalGuildTokenEarnedByPlayer; // Total guild token earned by player
    uint256 totalMintedLoootboxes;
    uint256 totalOpenedLoootboxes;
    uint256 totalMaticBalance;
    uint256 communityMaticBalance;
    uint256 lootboxMaticBalance;
    uint8 rewardRatioFromIncome; // From 1 to 100 (%)
    mapping(Rarity => uint8) lootboxDropChance; // From 1 to 100 (%)
    mapping(Rarity => uint8) rewardFactorByLootboxRarity; // From 1 to 100 (%)
    mapping(address => Admin) guildAdmins;
    mapping(address => Player) players;
    uint32 transferGasLimit;
    uint256 nPlayers;
    bool locked;
    string baseUri;
    string name;
    string symbol;
}

struct Admin {
    uint createdAt;
}

struct Player {
    uint createdAt;
    uint256 totalMintedLoootboxes;
    uint256 totalOpenedLoootboxes;
}

enum Rarity {
    level1,
    level2,
    level3,
    level4,
    level5
}

struct LootboxContent {
    uint256 guildTokens;
    uint256 maticTokens;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AppStorage} from "./LibAppStorage.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {LibMeta} from "./LibMeta.sol";

contract Modifiers {
    AppStorage internal s;

    modifier onlyGuildAdmin() {
        require(s.guildAdmins[LibMeta.msgSender()].createdAt > 0, "NOT_ALLOWED: Only guild admins can call this function");
        _;
    }

    modifier playerExists(address player) {
        require(player != address(0), "NOT_ALLOWED: Player address is not valid");
        require(s.players[player].createdAt > 0, "NOT_ALLOWED: Player does not exist");
        _;
    }

    modifier playerNotExists(address player) {
        require(player != address(0), "NOT_ALLOWED: Player address is not valid");
        require(!(s.players[player].createdAt > 0), "NOT_ALLOWED: Player already exists");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyGuildAdminOrGallion() {
        require(s.guildAdmins[LibMeta.msgSender()].createdAt > 0 || LibMeta.msgSender() == s.gallionLabs, "NOT_ALLOWED: Only Gallion can call this function");
        _;
    }

    modifier onlyGallion() {
        require(LibMeta.msgSender() == s.gallionLabs, "NOT_ALLOWED: Only Gallion can call this function");
        _;
    }

    modifier protectedCall() {
        LibDiamond.enforceIsContractOwner();
        require(LibMeta.msgSender() == address(this),
            "NOT_ALLOWED: Only Owner or this contract can call this function");
        _;
    }

    modifier noReentrant() {
        require(!s.locked, "No re-entrancy");
        s.locked = true;
        _;
        s.locked = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AppStorage, Player, Rarity, LootboxContent} from "./LibAppStorage.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {LibTokens} from "./LibTokens.sol";
import {LibUtils} from "./Utils.sol";

library LibLootbox {
    /**
     * @dev Emitted when a lootbox is opened.
     */
    event OpenLootboxEvent(address player, uint256 lootboxTokenId);

    function list(address playerAddress) internal view returns (uint256[] memory _lootboxBalances) {
        AppStorage storage s = LibDiamond.appStorage();

        uint256[] memory lootboxIds = new uint256[](5);
        lootboxIds[0] = s.lootboxIds[Rarity.level1];
        lootboxIds[1] = s.lootboxIds[Rarity.level2];
        lootboxIds[2] = s.lootboxIds[Rarity.level3];
        lootboxIds[3] = s.lootboxIds[Rarity.level4];
        lootboxIds[4] = s.lootboxIds[Rarity.level5];

        address[] memory playerAddresses = new address[](5);
        playerAddresses[0] = playerAddress;
        playerAddresses[1] = playerAddress;
        playerAddresses[2] = playerAddress;
        playerAddresses[3] = playerAddress;
        playerAddresses[4] = playerAddress;

        _lootboxBalances = LibTokens.balanceOfBatch(playerAddresses, lootboxIds);
    }

    /// @notice Award a lootbox for a player who has leveled up
    /// @param playerAddress The player to award the lootbox to
    /// @return _lootboxTokenId The awarded lootbox token id (1-5)
    function awardLevelUpLootbox(address playerAddress) internal returns (uint256 _lootboxTokenId) {
        AppStorage storage s = LibDiamond.appStorage();
        // calc the lootbox rarity
        uint random = LibUtils.random(100);
        Rarity rarity = Rarity.level1;
        for (uint8 i = 1; i < s.rarities.length; i++) {
            if (random <= s.lootboxDropChance[s.rarities[i]]) {
                rarity = Rarity(i);
            }
        }
        _lootboxTokenId = s.lootboxIds[rarity];
        // mint the lootbox
        mint(playerAddress, _lootboxTokenId, 1);
    }

    /// @notice Open a lootbox
    /// @dev This function throws for queries about the zero address and non-existing players.
    /// @param playerAddress The player to query
    /// @param lootboxTokenId The lootbox to open
    function open(address playerAddress, uint256 lootboxTokenId) internal {
        AppStorage storage s = LibDiamond.appStorage();
        uint rewardFactor = s.rewardFactorByLootboxRarity[s.lootboxRarity[lootboxTokenId]];
        // calc the Matic reward according to the guild balance
        uint maticTreasuryBalance = s.communityMaticBalance > s.lootboxMaticBalance ? s.lootboxMaticBalance : s.communityMaticBalance;
        uint playerReward = (rewardFactor * (maticTreasuryBalance / s.nPlayers)) / 100;
        // add/remove randomly -20%..+20% to the player reward
        uint factor = LibUtils.random(40);
        playerReward = playerReward * (100 + factor - 20) / 100;
        // send the Matic reward to the player
        (bool success, bytes memory data) = address(playerAddress).call{value : playerReward, gas : s.transferGasLimit}("");
        if (!success) {
            revert(string.concat("Error during send transaction: ", string(data)));
        }
        // send guild tokens to the player
        LibTokens.mint(playerAddress, s.guildTokenId, s.guildTokensByLootbox[Rarity.level1], "0x0");
        // burn the lootbox
        LibTokens.burn(playerAddress, lootboxTokenId, 1);
        // adjust guild balances
        s.communityMaticBalance -= playerReward;
        if (s.communityMaticBalance < s.lootboxMaticBalance) {
            s.lootboxMaticBalance = s.communityMaticBalance / 2;
        }
        s.totalMaticBalance -= playerReward;
        s.totalOpenedLoootboxes++;
        s.players[playerAddress].totalOpenedLoootboxes++;
        s.lastLootboxContents[playerAddress] = LootboxContent(s.guildTokensByLootbox[Rarity.level1], playerReward);
        s.totalOpenedLoootboxesByPlayer[playerAddress][lootboxTokenId]++;
        s.totalMaticEarnedByPlayer[playerAddress] += playerReward;
        s.totalGuildTokenEarnedByPlayer[playerAddress] += s.guildTokensByLootbox[Rarity.level1];
        emit OpenLootboxEvent(playerAddress, lootboxTokenId);
    }

    /// @notice Mint a lootbox for a player
    /// @param playerAddress The player to mint the lootbox for
    /// @param lootboxTokenId The type of lootbox to mint
    /// @param amount The amount of lootboxes to mint
    function mint(address playerAddress, uint256 lootboxTokenId, uint256 amount) internal {
        AppStorage storage s = LibDiamond.appStorage();
        LibTokens.mint(playerAddress, lootboxTokenId, amount, "0x0");
        s.players[playerAddress].totalMintedLoootboxes += amount;
        s.totalMintedLoootboxesByPlayer[playerAddress][lootboxTokenId] += amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
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
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { AppStorage } from "./LibAppStorage.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AppStorage, Player, Rarity} from "./LibAppStorage.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {LibUtils} from "./Utils.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";


library LibTokens {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) internal view returns (uint256) {
        AppStorage storage s = LibDiamond.appStorage();
        return s._balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    internal
    view
    returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        AppStorage storage s = LibDiamond.appStorage();
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        s._balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(address(0), amounts);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        AppStorage storage s = LibDiamond.appStorage();
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            s._balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(address(0), amounts);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        AppStorage storage s = LibDiamond.appStorage();
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = s._balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
        s._balances[id][from] = fromBalance - amount;
    }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(from, amounts);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        AppStorage storage s = LibDiamond.appStorage();
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = s._balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            s._balances[id][from] = fromBalance - amount;
        }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(from, amounts);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {}

    function _afterTokenTransfer(
        address from,
        uint256[] memory amounts
    ) internal {
        if (from == address(0)) {
            AppStorage storage s = LibDiamond.appStorage();
            s.totalMintedLoootboxes += amounts.length;
        }
    }

    function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library LibUtils {

    // string comparison
    function compareStrings(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return - 1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return - 1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    // string comparison
    function areStringsEqual(string memory _a, string memory _b) internal pure returns (bool) {
        return compareStrings(_a, _b) == 0;
    }

    // generate a random number between 0 and the given max
    function random(uint number) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % number;
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function strWithUint(string memory _str, uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        bytes memory buffer;
    unchecked {
        if (value == 0) {
            return string(abi.encodePacked(_str, "0"));
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
    }
        return string(abi.encodePacked(_str, buffer));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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