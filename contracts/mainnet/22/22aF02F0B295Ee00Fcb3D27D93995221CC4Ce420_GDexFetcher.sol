// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./interfaces/IGladiatorDexHero.sol";
import "./interfaces/IShield.sol";
import "./interfaces/IWeapon.sol";

contract GDexFetcher {
    IGladiatorDexHero heroContract;
    IShield shieldContract;
    IWeapon weaponContract;

    constructor(address _heroContract, address _shieldContract, address _weaponContract) {
        heroContract = IGladiatorDexHero(_heroContract);
        shieldContract = IShield(_shieldContract);
        weaponContract = IWeapon(_weaponContract);
    }

    function getAllStats(uint256 heroTokenId, uint256 shieldTokenId, uint256 weaponTokenId) public view returns(
        IGladiatorDexHero.HeroInfo memory hero,
        IShield.ShieldInfo memory shield,
        IWeapon.WeaponInfo memory weapon
    ) {
        hero = heroContract.getHeroInfo(heroTokenId);
        shield = shieldContract.getShieldInfo(shieldTokenId);
        weapon = weaponContract.getWeaponInfo(weaponTokenId);
    }

    function verifyOwnership(address player, uint256 heroTokenId, uint256 shieldTokenId, uint256 weaponTokenId) public view returns(bool) {
        if(
            heroContract.ownerOf(heroTokenId) == shieldContract.ownerOf(shieldTokenId) &&
            shieldContract.ownerOf(shieldTokenId) == weaponContract.ownerOf(weaponTokenId) &&
            player == weaponContract.ownerOf(weaponTokenId)
        ){
            return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
interface IGladiatorDexHero {

    struct HeroInfo {
        uint256 tokenId;
        uint256 power;
        uint256 dexterity;
        uint256 intelligence;
        uint256 fightCount;
        uint256 apprenticeCount;
        uint256 rank;
        uint256 modelId;
    }

    function safeMint(address player) external;
    function safeMintBulk(address player, uint256 quantity) external;
    function executeApprenticeship(address player, uint256 master1, uint256 master2, uint256 nonce) external;
    function executeTraining(address player, uint256 tokenId, uint256[] memory burnTokenIds, uint256 nonce) external;
    function getHeroInfo(uint256 tokenId) external view returns(HeroInfo memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
interface IShield {
    struct ShieldInfo {
        uint256 tokenId;
        uint256 defense;
        uint256 durability;
        uint256 rank;
        uint256 modelId;
    }
    function safeMint(address to, uint256 nonce) external;
    function safeMintBulk(address player, uint256 quantity) external;
    function getShieldInfo(uint256 tokenId) external view returns(ShieldInfo memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function executeForging(address player, uint256 tokenId, uint256[] memory burnTokenIds, uint256 nonce) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
interface IWeapon {
    struct WeaponInfo {
        uint256 tokenId;
        uint256 attack;
        uint256 durability;
        uint256 rank;
        uint256 modelId;
    }
    function safeMint(address to, uint256 nonce) external;
    function safeMintBulk(address player, uint256 quantity) external;
    function getWeaponInfo(uint256 tokenId) external view returns(WeaponInfo memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function executeForging(address player, uint256 tokenId, uint256[] memory burnTokenIds, uint256 nonce) external;
}