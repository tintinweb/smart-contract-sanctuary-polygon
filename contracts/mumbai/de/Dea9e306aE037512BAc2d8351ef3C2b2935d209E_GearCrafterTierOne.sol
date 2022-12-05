// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../IGear.sol";
import "../../thesea/ITheTreasureSea.sol";
import "../../character/ICharacter.sol";

contract GearCrafterTierOne is ReentrancyGuard {
    ITheTreasureSea internal theSea;
    IGear internal gear;
    ICharacter internal characters;
    // Rarity
    uint32 internal constant COMMON = 0;
    uint32 internal constant RARE = 1;
    uint32 internal constant LEGENDARY = 2;
    // Tier
    uint32 internal constant tierOne = 1;
    uint256 amountMapToBurn = 100;
    address owner;
    uint256 internal mintPrice;
    address treasuryGuild;
    uint64 internal expCommon = 10;
    uint64 internal expRare = 20;
    uint64 internal expLegendary = 30;

    mapping(uint256 => Attribut) internal attributs;
    struct Attribut {
        uint32 Minboarding;
        uint32 Maxboarding;
        uint32 Minsailing;
        uint32 Maxsailing;
        uint32 Mincharisma;
        uint32 Maxcharisma;
        uint64 experience;
        uint32 rarity;
    }

    constructor(
        address _theSea,
        address _gear,
        address _characters,
        address _treasuryGuild
    ) {
        theSea = ITheTreasureSea(_theSea);
        gear = IGear(_gear);
        characters = ICharacter(_characters);
        owner = msg.sender;
        mintPrice = 10**15;
        treasuryGuild = _treasuryGuild;
        setAttribut();
    }

    // Modifier
    modifier onlyHuman() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(
            size == 0,
            "only humans allowed! (code present at caller address)"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner!");
        _;
    }

    function setAttribut() internal {
        // Common
        attributs[COMMON].Minboarding = 5;
        attributs[COMMON].Maxboarding =
            15 -
            (attributs[COMMON].Minboarding - 1);
        attributs[COMMON].Minsailing = 5;
        attributs[COMMON].Maxsailing = 15 - (attributs[COMMON].Minsailing - 1);
        attributs[COMMON].Mincharisma = 5;
        attributs[COMMON].Maxcharisma =
            15 -
            (attributs[COMMON].Mincharisma - 1);
        attributs[COMMON].rarity = COMMON;
        attributs[COMMON].experience = expCommon;
        // Rare
        attributs[RARE].Minboarding = 10;
        attributs[RARE].Maxboarding = 25 - (attributs[RARE].Minboarding - 1);
        attributs[RARE].Minsailing = 10;
        attributs[RARE].Maxsailing = 25 - (attributs[RARE].Minsailing - 1);
        attributs[RARE].Mincharisma = 10;
        attributs[RARE].Maxcharisma = 25 - (attributs[RARE].Mincharisma - 1);
        attributs[RARE].rarity = RARE;
        attributs[RARE].experience = expRare;
        // Legendary
        attributs[LEGENDARY].Minboarding = 15;
        attributs[LEGENDARY].Maxboarding =
            40 -
            (attributs[LEGENDARY].Minboarding - 1);
        attributs[LEGENDARY].Minsailing = 15;
        attributs[LEGENDARY].Maxsailing =
            40 -
            (attributs[LEGENDARY].Minsailing - 1);
        attributs[LEGENDARY].Mincharisma = 15;
        attributs[LEGENDARY].Maxcharisma =
            40 -
            (attributs[LEGENDARY].Mincharisma - 1);
        attributs[LEGENDARY].rarity = LEGENDARY;
        attributs[LEGENDARY].experience = expLegendary;
    }

    function craftGear(
        uint256 characterId,
        uint32 numberOfmints,
        uint32 rarity
    ) external payable onlyHuman nonReentrant {
        require(msg.value >= mintPrice * numberOfmints, "Gas amount too low!");
        require(
            characters.ownerOf(characterId) == msg.sender,
            "Not Your Character!"
        );
        require(
            rarity == COMMON || rarity == RARE || rarity == LEGENDARY,
            "Wrong Rarity!"
        );
        theSea.burn(msg.sender, rarity, (amountMapToBurn * numberOfmints));
        gear.generateGear(
            msg.sender,
            tierOne,
            rarity,
            characterId,
            numberOfmints
        );
        (bool success, ) = payable(treasuryGuild).call{value: msg.value}("");
        require(success, "Failed to send Ether");
    }

    function mintGear(uint256 rarity)
        external
        view
        returns (Attribut memory attributs_)
    {
        return attributs[rarity];
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setTreasuryGuild(address _newTreasuryGuild) external onlyOwner {
        treasuryGuild = _newTreasuryGuild;
    }

    function setCharacter(address _characters) external onlyOwner {
        characters = ICharacter(_characters);
    }

    function setGear(address _gear) external onlyOwner {
        gear = IGear(_gear);
    }

    function setTreasureSea(address _theSea) external onlyOwner {
        theSea = ITheTreasureSea(_theSea);
    }

    function fetchMintPrice() external view returns (uint256) {
        return mintPrice;
    }

    function fetchAmountMapToBurn() external view returns (uint256) {
        return amountMapToBurn;
    }
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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface IGear {
    struct Gear {
        uint32 boarding;
        uint32 sailing;
        uint32 charisma;
        uint64 experience;
        uint32 slot;
        uint32 rarity;
        uint32 tier;
        uint256 tokenId;
    }

    function generateGear(
        address user,
        uint32 tier,
        uint32 rarity,
        uint256 characterId,
        uint32 numberOfmints
    ) external;

    function burnGear(uint256 tokenId) external;

    function getGearStats(uint256 tokenId)
        external
        view
        returns (Gear memory gear);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface ITheTreasureSea {
    function mintTreasureMap(
        address user,
        uint256 amount,
        uint256 rarity
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 value
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICharacter {
    struct Character {
        uint32 boarding;
        uint32 sailing;
        uint32 charisma;
        uint64 experience;
        uint64 specialisation;
        uint32 thirst;
        uint256 tokenId;
    }

    //View functions
    function addTreasuryHuntResult(
        uint256 tokenId,
        uint32 amountHunt,
        uint64 exp
    ) external;

    function generateCharacter(
        uint256 class,
        address user,
        uint32 numberOfmints
    ) external;

    function getCharacterInfos(uint256 tokenId)
        external
        view
        returns (Character memory characterInfos);

    function getLevelMax() external view returns (uint256);

    function getNumberOfCharacters() external view returns (uint256);

    function getCharacterTotalStats(uint256 tokenId)
        external
        view
        returns (
            uint32 boarding,
            uint32 sailing,
            uint32 charisma
        );

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function setApprovalForAll(address operator, bool _approved) external;

    function burn(uint256 tokenId) external;
}