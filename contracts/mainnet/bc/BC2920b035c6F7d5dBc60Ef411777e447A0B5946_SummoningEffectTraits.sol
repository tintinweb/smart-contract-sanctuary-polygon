// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISummoningEffectTypes {
    enum ElementType {
        None,
        Fire,
        Water,
        Wind,
        Earth,
        Health
    }

    enum SummoningLevel {
        None,
        Light,
        Medium,
        Ultimate
    }

    struct SummoningEffect {
        ElementType elementType;
        SummoningLevel summoningLevel;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ISummoningEffectTypes.sol";

library SummoningEffectTraits {
    function packSummoningEffect(
        ISummoningEffectTypes.ElementType elementType,
        ISummoningEffectTypes.SummoningLevel summoningLevel
    ) public pure returns (uint16 combinedEnums) {
        require(
            uint(elementType) <= 0xFFFF,
            "SummoningEffectTraits: Type value is too large"
        );
        require(
            uint(summoningLevel) <= 0xFFFF,
            "SummoningEffectTraits: Level value is too large"
        );

        combinedEnums =
            (uint16(uint(elementType)) << 8) |
            uint16(uint(summoningLevel));
    }

    function unpackSummoningEffect(
        uint16 combinedEnums
    )
        public
        pure
        returns (
            ISummoningEffectTypes.ElementType elementType,
            ISummoningEffectTypes.SummoningLevel summoningLevel
        )
    {
        elementType = ISummoningEffectTypes.ElementType(
            uint8(combinedEnums >> 8)
        );
        summoningLevel = ISummoningEffectTypes.SummoningLevel(
            uint8(combinedEnums & 0xFF)
        );
    }

    function getSummoningEffect(
        uint256 random
    ) public pure returns (ISummoningEffectTypes.SummoningEffect memory) {
        return
            ISummoningEffectTypes.SummoningEffect(
                getSummoningEffectType(random),
                getSummoningLevel(random)
            );
    }

    function getSummoningEffectType(
        uint256 random
    ) public pure returns (ISummoningEffectTypes.ElementType) {
        uint256 scaledRandom = random % 100;

        if (scaledRandom < 20) {
            return ISummoningEffectTypes.ElementType.Fire;
        } else if (scaledRandom < 40) {
            return ISummoningEffectTypes.ElementType.Water;
        } else if (scaledRandom < 60) {
            return ISummoningEffectTypes.ElementType.Wind;
        } else if (scaledRandom < 80) {
            return ISummoningEffectTypes.ElementType.Earth;
        } else {
            return ISummoningEffectTypes.ElementType.Health;
        }
    }

    function getSummoningEffectTypeLabel(
        ISummoningEffectTypes.ElementType elementType
    ) public pure returns (string memory) {
        if (elementType == ISummoningEffectTypes.ElementType.Fire) {
            return "Fire";
        } else if (elementType == ISummoningEffectTypes.ElementType.Water) {
            return "Water";
        } else if (elementType == ISummoningEffectTypes.ElementType.Wind) {
            return "Wind";
        } else if (elementType == ISummoningEffectTypes.ElementType.Earth) {
            return "Earth";
        } else if (elementType == ISummoningEffectTypes.ElementType.Health) {
            return "Health";
        } else {
            return "None";
        }
    }

    function getSummoningLevel(
        uint256 random
    ) public pure returns (ISummoningEffectTypes.SummoningLevel) {
        uint256 scaledRandom = random % 100;

        if (scaledRandom < 60) {
            return ISummoningEffectTypes.SummoningLevel.Light;
        } else if (scaledRandom < 90) {
            return ISummoningEffectTypes.SummoningLevel.Medium;
        } else {
            return ISummoningEffectTypes.SummoningLevel.Ultimate;
        }
    }

    function getSummoningLevelLabel(
        ISummoningEffectTypes.SummoningLevel summoningLevel
    ) public pure returns (string memory) {
        if (summoningLevel == ISummoningEffectTypes.SummoningLevel.Light) {
            return "Light";
        } else if (
            summoningLevel == ISummoningEffectTypes.SummoningLevel.Medium
        ) {
            return "Medium";
        } else if (
            summoningLevel == ISummoningEffectTypes.SummoningLevel.Ultimate
        ) {
            return "Ultimate";
        } else {
            return "None";
        }
    }
}