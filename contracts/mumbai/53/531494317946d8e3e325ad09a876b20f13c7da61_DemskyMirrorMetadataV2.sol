// SPDX-License-Identifier: MIT

/**
       ###    ##    ## #### ##     ##    ###
      ## ##   ###   ##  ##  ###   ###   ## ##
     ##   ##  ####  ##  ##  #### ####  ##   ##
    ##     ## ## ## ##  ##  ## ### ## ##     ##
    ######### ##  ####  ##  ##     ## #########
    ##     ## ##   ###  ##  ##     ## ##     ##
    ##     ## ##    ## #### ##     ## ##     ##
*/

pragma solidity ^0.8.10;
pragma abicoder v2;
import "./StringsUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./base64.sol";
import "./AnimaMetadata.sol";
contract DemskyMirrorMetadataV2 is AnimaMetadata, OwnableUpgradeable, AccessControlEnumerableUpgradeable {
    //
    // GAP
    // !! This can potentially be used in the future to add new base classes !!
    //
    uint256[50] private __gap;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");

    event Unlock(uint256 indexed tokenId, bytes32 indexed location);

    struct TokenAttributes {
        bool minted;
        uint256 blockTimestamp;
        uint8 generation;
        uint8 form;
        uint8 spectrum;
        uint8 vibration;
        uint8 fluctuation;
        uint8 harmonics;
        uint8 oscillation;
        uint8 perlin;
        uint8 frequency;
        bytes32[8] unlocks;
    }

    struct OptionalString {
        bool present;
        string value;
    }

    struct IntermediateAttributes {
        string tokenId;
        string form;
        string spectrum;
        string vibration;
        OptionalString fluctuation;
        OptionalString harmonics;
        OptionalString oscillation;
        string perlin;
        string frequency;
        string generation;
    }

    struct UnlockLocation {
        bool exists;
        string name;
        string emoji;
        string encoded;
    }

    mapping(uint256 => TokenAttributes) private attributeMap;
    mapping(bytes32 => UnlockLocation) private locationMap;

    function initialize() public initializer {
        // Note: this is technically not recommended, but the alternative is simply not using multiple inheritance:
        //   https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/README.md
        // Since it seems like this is way better than re-implementing interfaces that already exist,
        //   confirm that all parent contracts are initialized _once_ and in the correct order here
        __Context_init_unchained();
        __Ownable_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, owner());
    }

    receive() external payable {}

    fallback() external {}

    function tokenMinted(uint256 _tokenId) external override onlyRole(MINTER_ROLE) {
        TokenAttributes storage attributes = attributeMap[_tokenId];
        require(attributes.minted == false, "TOKEN_ALREADY_MINTED");
        attributes.minted = true;
        attributes.blockTimestamp = block.timestamp;
        attributes.generation = 0;
        attributes.form = getPseudoRandomOneToOneHundred(_tokenId, attributes.blockTimestamp, "form");
        attributes.spectrum = getPseudoRandomOneToOneHundred(_tokenId, attributes.blockTimestamp, "spectrum");
        attributes.vibration = getPseudoRandomOneToOneHundred(_tokenId, attributes.blockTimestamp, "vibration");
        attributes.fluctuation = getPseudoRandomOneToOneHundred(_tokenId, attributes.blockTimestamp, "fluctuation");
        attributes.harmonics = getPseudoRandomOneToOneHundred(_tokenId, attributes.blockTimestamp, "harmonics");
        attributes.oscillation = getPseudoRandomOneToOneHundred(_tokenId, attributes.blockTimestamp, "oscillation");
        attributes.perlin = getPseudoRandomOneToOneHundred(_tokenId, attributes.blockTimestamp, "perlin");
        attributes.frequency = getPseudoRandomOneToOneHundred(_tokenId, attributes.blockTimestamp, "frequency");
    }

    function tokenDataURI(uint256 _tokenId) external view override returns (string memory) {
        TokenAttributes storage attributes = attributeMap[_tokenId];
        require(attributes.minted == true, "TOKEN_NOT_MINTED");

        OptionalString memory oscillation = determineFluctuationOrHarmonicsOrOscillation(attributes.oscillation);
        IntermediateAttributes memory intermediate = IntermediateAttributes({
            tokenId: StringsUpgradeable.toString(_tokenId),
            form: determineForm(attributes.form),
            spectrum: determineSpectrum(attributes.spectrum),
            vibration: determineVibration(attributes.vibration),
            fluctuation: determineFluctuationOrHarmonicsOrOscillation(attributes.fluctuation),
            harmonics: determineFluctuationOrHarmonicsOrOscillation(attributes.harmonics),
            oscillation: oscillation,
            perlin: determinePerlin(oscillation.present, attributes.perlin),
            frequency: determineFrequency(oscillation.present, attributes.frequency),
            generation: StringsUpgradeable.toString(attributes.generation)
        });

        string memory locationAttributes = "";
        string memory locationQuery = "?l=";
        for (uint8 i = 0; i < attributes.generation; i++) {
            UnlockLocation storage location = locationMap[attributes.unlocks[i]];
            if (location.exists) {
                locationAttributes = string(
                    abi.encodePacked(
                        locationAttributes,
                        '{"trait_type":"Site","value":"',
                        location.emoji,
                        " ",
                        location.name,
                        '"},'
                    )
                );
                locationQuery = string(abi.encodePacked(locationQuery, i == 0 ? "" : ",", location.encoded));
            }
        }

        string memory dynamicPathPostfix = string(
            abi.encodePacked(
                abi.encodePacked(
                    intermediate.tokenId,
                    "/",
                    intermediate.form,
                    "/",
                    intermediate.spectrum,
                    "/",
                    intermediate.vibration,
                    "/",
                    intermediate.fluctuation.value,
                    "/",
                    intermediate.harmonics.value
                ),
                "/",
                intermediate.oscillation.value,
                "/",
                intermediate.perlin,
                "/",
                intermediate.frequency,
                locationQuery
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            abi.encodePacked(
                                '{"name":"Mirror #',
                                intermediate.tokenId,
                                '","description":"Edition ',
                                intermediate.tokenId,
                                ' of 8888","external_url":"https://marketplace.staging.animavirtuality.com/demsky/mirror/',
                                intermediate.tokenId,
                                '","image":"https://dynamic-textures.staging.animavirtuality.com/cover/demsky/mirror/',
                                dynamicPathPostfix,
                                '","animaUrl":"https://dynamic-textures.staging.animavirtuality.com/manifest/demsky/mirror/',
                                dynamicPathPostfix,
                                '","attributes":['
                            ),
                            abi.encodePacked('{"trait_type":"Form","value":"', intermediate.form, '"},'),
                            abi.encodePacked('{"trait_type":"Spectrum","value":"', intermediate.spectrum, '"},'),
                            abi.encodePacked('{"trait_type":"Vibration","value":"', intermediate.vibration, '"},'),
                            intermediate.fluctuation.present
                                ? abi.encodePacked(
                                    '{"trait_type":"Fluctuation","value":"',
                                    intermediate.fluctuation.value,
                                    '"},'
                                )
                                : bytes(""),
                            intermediate.harmonics.present
                                ? abi.encodePacked(
                                    '{"trait_type":"Harmonics","value":"',
                                    intermediate.harmonics.value,
                                    '"},'
                                )
                                : bytes(""),
                            intermediate.oscillation.present
                                ? abi.encodePacked(
                                    abi.encodePacked(
                                        '{"trait_type":"Oscillation","value":"',
                                        intermediate.oscillation.value,
                                        '"},'
                                    ),
                                    abi.encodePacked('{"trait_type":"Perlin","value":"', intermediate.perlin, '"},'),
                                    abi.encodePacked(
                                        '{"trait_type":"Frequency","value":"',
                                        intermediate.frequency,
                                        '"},'
                                    )
                                )
                                : bytes(""),
                            locationAttributes,
                            abi.encodePacked(
                                '{"trait_type":"Generation","value":',
                                intermediate.generation,
                                ',"max_value":8}'
                            ),
                            "]}"
                        )
                    )
                )
            );
    }

    function addUnlockLocation(
        string calldata _name,
        string calldata _emoji,
        string calldata _encoded
    ) external onlyRole(ADMIN_ROLE) {
        bytes32 locationHash = keccak256(abi.encodePacked(_name));
        UnlockLocation storage location = locationMap[locationHash];

        location.exists = true;
        location.name = _name;
        location.emoji = _emoji;
        location.encoded = _encoded;
    }

    function unlockLocation(uint256 _tokenId, string calldata _name) external onlyRole(GAME_ROLE) {
        bytes32 locationHash = keccak256(abi.encodePacked(_name));
        UnlockLocation storage location = locationMap[locationHash];
        require(location.exists == true, "LOCATION_NONEXISTENT");

        TokenAttributes storage attributes = attributeMap[_tokenId];
        require(attributes.minted == true, "TOKEN_NOT_MINTED");
        require(attributes.generation < 8, "MAX_GENERATIONS");

        for (uint8 i = 0; i < attributes.generation; i++) {
            require(attributes.unlocks[i] != locationHash, "ALREADY_UNLOCKED");
        }

        attributes.unlocks[attributes.generation] = locationHash;
        attributes.generation = attributes.generation + 1;
        emit Unlock(_tokenId, locationHash);
    }

    function getPseudoRandomOneToOneHundred(
        uint256 _tokenId,
        uint256 _blockTimestamp,
        string memory _attributeName
    ) private pure returns (uint8) {
        // rand(0..99) + 1
        return uint8((uint256(keccak256(abi.encodePacked(_tokenId, _blockTimestamp, _attributeName))) % 100) + 1);
    }

    function determineForm(uint8 _roll) private pure returns (string memory) {
        if (_roll < 1) {
            // Sanity check
            return "Adhara";
        }

        if (_roll <= 3) {
            // 3%  (0,3]
            return "Mirzam";
        } else if (_roll <= 11) {
            // 8%  (3,11]
            return "Zeta";
        } else if (_roll <= 24) {
            // 13% (11,24]
            return "Sirius";
        } else if (_roll <= 45) {
            // 21% (24,45]
            return "Aludra";
        } else {
            // 55% (45,100]
            return "Adhara";
        }
    }

    function determineSpectrum(uint8 _roll) private pure returns (string memory) {
        if (_roll < 1) {
            // Sanity check
            return "Optica";
        }

        if (_roll <= 11) {
            // 11% (0,11]
            return "Modula";
        } else if (_roll <= 24) {
            // 13% (11,24]
            return "Ultra";
        } else if (_roll <= 45) {
            // 21% (24,45]
            return "Infra";
        } else {
            // 55% (45,100]
            return "Optica";
        }
    }

    function determineVibration(uint8 _roll) private pure returns (string memory) {
        if (_roll < 1) {
            // Sanity check
            return "3";
        }

        if (_roll <= 12) {
            // 12% (0,12]
            return "7";
        } else if (_roll <= 45) {
            // 33% (12,33]
            return "5";
        } else {
            // 55% (45,100]
            return "3";
        }
    }

    function determineFluctuationOrHarmonicsOrOscillation(uint8 _roll) private pure returns (OptionalString memory) {
        if (_roll < 1) {
            // Sanity check
            return OptionalString({present: false, value: "0"});
        }

        if (_roll <= 1) {
            // 1% (0,1]
            return OptionalString({present: true, value: "10"});
        } else if (_roll <= 2) {
            // 1% (1,2]
            return OptionalString({present: true, value: "9"});
        } else if (_roll <= 4) {
            // 2% (2,4]
            return OptionalString({present: true, value: "8"});
        } else if (_roll <= 7) {
            // 3% (4,7]
            return OptionalString({present: true, value: "7"});
        } else if (_roll <= 11) {
            // 4% (7,11]
            return OptionalString({present: true, value: "6"});
        } else if (_roll <= 16) {
            // 5% (11,16]
            return OptionalString({present: true, value: "5"});
        } else if (_roll <= 22) {
            // 6% (16,22]
            return OptionalString({present: true, value: "4"});
        } else if (_roll <= 29) {
            // 7% (22,29]
            return OptionalString({present: true, value: "3"});
        } else if (_roll <= 37) {
            // 8% (29,37]
            return OptionalString({present: true, value: "2"});
        } else if (_roll <= 46) {
            // 9% (37,46]
            return OptionalString({present: true, value: "1"});
        } else {
            // 54% (46,100]
            return OptionalString({present: false, value: "0"});
        }
    }

    function determinePerlin(bool _oscillationPresent, uint8 _roll) private pure returns (string memory) {
        if (_roll < 1 || !_oscillationPresent) {
            // Sanity check
            return "0";
        }

        if (_roll <= 10) {
            // 10% (0,10]
            return "9";
        } else if (_roll <= 20) {
            // 10% (10,20]
            return "8";
        } else if (_roll <= 30) {
            // 10% (20,30]
            return "7";
        } else if (_roll <= 40) {
            // 10% (30,40]
            return "6";
        } else if (_roll <= 50) {
            // 10% (40,50]
            return "5";
        } else if (_roll <= 60) {
            // 10% (50,60]
            return "4";
        } else if (_roll <= 70) {
            // 10% (60,70]
            return "3";
        } else if (_roll <= 80) {
            // 10% (70,80]
            return "2";
        } else if (_roll <= 90) {
            // 10% (80,90]
            return "1";
        } else {
            // 10% (90,100]
            return "0";
        }
    }

    function determineFrequency(bool _oscillationPresent, uint8 _roll) private pure returns (string memory) {
        if (_roll < 1 || !_oscillationPresent) {
            // Sanity check
            return "1";
        }

        if (_roll <= 11) {
            // 11% (0,11]
            return "4";
        } else if (_roll <= 24) {
            // 13% (11,24]
            return "3";
        } else if (_roll <= 45) {
            // 21% (24,45]
            return "2";
        } else {
            // 55% (45,100]
            return "1";
        }
    }
}