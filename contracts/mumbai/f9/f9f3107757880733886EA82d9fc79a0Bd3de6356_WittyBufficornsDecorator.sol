// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IWittyBufficornsDecorator.sol";

/// @title Decorator contract providing specific art content for Liscon 2021.
/// @author Otherplane Labs, 2021.
contract WittyBufficornsDecorator
    is
        IWittyBufficornsDecorator,
        Ownable
{
    using Strings for uint256;
    using WittyBufficornsLib for WittyBufficornsLib.Awards;
    using WittyBufficornsLib for WittyBufficornsLib.Traits;

    struct Boosters {
        uint[] odds;
        uint[] values;
        uint32 range;
    }

    Boosters public boosters;
    bool public forged;    

    modifier isForged {
        require(forged, "WittyBufficornsDecorator: not forged");
        _;
    }

    modifier notForged {
        require(!forged, "WittyBufficornsDecorator: already forged");
        _;
    }

    constructor(string memory _baseURI) {
        setBaseURI(_baseURI);
        baseURI = _baseURI;
        boosters.odds = [ 225, 16, 8, 4, 2, 1 ];
        boosters.values = [ 0, 10, 20, 30, 40, 50 ];
        boosters.range = 256;
    }    

    function forge()
        external virtual
        notForged
        onlyOwner
    {
        forged = true;
    }

    function setBaseURI(string memory _baseURI)
        public virtual
        onlyOwner
    {
        bytes memory _rawURI = bytes(_baseURI);
        require(
            _rawURI.length > 0,
            "WittyBufficornsDecorator: empty URI"
        );
        require(
            _rawURI[_rawURI.length - 1] == "/",
            "WittyBufficornsDecorator: no trailing slash"
        );
        baseURI = _baseURI;   
    }

    function setBoosters(uint[] calldata _odds, uint[] calldata _values)
        external virtual
        notForged
        onlyOwner
    {
        require(_values.length == _odds.length, "WittyBufficornsDecorator: range mismatch");
        boosters.odds = _odds;
        boosters.values = _values;
        uint _range;
        for (uint _index = 0; _index < _odds.length; _index ++) {
            _range += _odds[_index];
        }
    }


    // ========================================================================
    // --- Implementation of IWittyBufficornsDecorator ------------------------

    string public override baseURI;

    function lookupMedalCaption(uint256 _ranking)
        public pure
        virtual override
        returns (string memory)
    {
        if (_ranking == 1) {
            return "Gold";
        } else if (_ranking == 2) {
            return "Silver";
        } else if (_ranking == 3) {
            return "Bronze";
        } else {
            return "Stone";
        }
    }

    function lookupRanchName(uint256 _ranchId)
        public pure
        virtual override
        returns (string memory)
    {
        if (_ranchId == 0) {
            return "Gold Reef Co.";
        } else if (_ranchId == 1) {
            return "Infinite Harmony Farm";
        } else if (_ranchId == 2) {
            return "Balancer Peak State";
        } else if (_ranchId == 3) {
            return "The Ol' Algoranch";
        } else if (_ranchId == 4) {
            return "Vega Slopes Range";
        } else if (_ranchId == 5) {
            return "Opolis Reservation";
        } else {
            return "Mystery Ranch";
        }
    }

    function lookupRanchResource(uint256 _ranchId)
        public pure
        virtual override
        returns (string memory)
    {
        if (_ranchId == 0) {
            // Gold Reef Co. => Warm Hay
            return "Warm Hay";
        } else if (_ranchId == 1) {
            // Infinite Harmony Farm => Fresh Grass
            return "Fresh Grass";
        } else if (_ranchId == 2) {
            // Balancer Peak State => Fresh Grass
            return "Smart Sedge";
        } else if (_ranchId == 3) {
            // The Ol' Algoranch => Mighty Acorn
            return "Mighty Acorn";
        } else if (_ranchId == 4) {
            // Vega Slopes Range => Tireless Water
            return "Tireless Water";
        } else if (_ranchId == 5) {
            // Opolis Reservation => Hearty Berry
            return "Hearty Berry";
        } else {
            return "Mystery Resource";
        }
    }

    function lookupRanchWeatherStation(uint256 _ranchId)
        public pure 
        virtual override
        returns (bytes4)
    {
        if (_ranchId == 0) {
            // Gold Reef Co. => Trinidad => KVTP
            return bytes4("KVTP");
        } else if (_ranchId == 2) {
            // Balancer Peak State => Silverton => KCPW
            return bytes4("KCPW");
        } else if (_ranchId == 3) {
            // The Ol' Algoranch => Colorado Springs => KMNH
            return bytes4("KMNH");
        } else if (_ranchId == 4) {
            // Vega Slopes Range => Breckenridge => KBJC
            return bytes4("KBJC");
        } else if (_ranchId == 5) {
            // Opolis Reservation => Pueblo => KLHX
            return bytes4("KLHX");
        } else {
            // Otherwise => Denver => KDEN
            return bytes4("KDEN");
        }
    }

    function toJSON(
            uint256 _tokenId,
            bytes32 _randomness,
            WittyBufficornsLib.TokenMetadata calldata _metadata
        )
        external view
        virtual override
        isForged
        returns (string memory)
    {
        if (_randomness != bytes32(0)) {
            // convolute given randomness and unique farmer name
            _randomness = keccak256(abi.encode(_randomness, _metadata.farmer.name));
        }
        string memory _tokenIdStr = _tokenId.toString();
        string memory _baseURI = baseURI;

        string memory _name = string(abi.encodePacked(
            "\"name\": \"Witty Bufficorns Award #", _tokenIdStr, "\","
        ));
        string memory _description = string(abi.encodePacked(
            "\"description\": \"",
            _loadDescription(_metadata),
            "\","
        ));        
        string memory _externalUrl = string(abi.encodePacked(
            "\"external_url\": \"", _baseURI, "metadata/", _tokenIdStr, "\","
        ));
        string memory _image = string(abi.encodePacked(
            "\"image\": \"", _baseURI, "image/", _tokenIdStr, "\","  
        ));
        string memory _attributes = string(abi.encodePacked(
            "\"attributes\": [",
            _loadAttributes(_randomness, _metadata),
            "]"
        ));
        return string(abi.encodePacked(
            "{", _name, _description, _externalUrl, _image, _attributes, "}"
        ));
    }


    // ========================================================================
    // --- INTERNAL METHODS ---------------------------------------------------

    function _getRandomTraitBoost(uint32 _range, uint8 _traitIndex, bytes32 _randomness)
        internal view
        returns (uint _value)
    {
        uint8 _random = uint8(WittyBufficornsLib.random(_range, uint(_traitIndex), _randomness));
        uint _index; uint _maxIndex = boosters.odds.length; uint _odds;
        for (_index = 0; _index < _maxIndex; _index ++) {
            _odds += boosters.odds[_index];
            if (_random < _odds) break;
        }
        if (_index < _maxIndex) {
            _value = boosters.values[_index];
        }
    }

    function _loadDescription(WittyBufficornsLib.TokenMetadata memory _metadata)
        internal pure
        returns (string memory _json)
    {
        WittyBufficornsLib.Awards _category = _metadata.tokenInfo.award.category;
        if (_category == WittyBufficornsLib.Awards.BestBreeder) {
            _json = string(abi.encodePacked(
                "Player ", _metadata.farmer.name, 
                " ranked as #",
                _metadata.tokenInfo.award.ranking.toString(),
                " ", _metadata.tokenInfo.award.category.toString()
            ));
        } else if (_category == WittyBufficornsLib.Awards.BestRanch) {
            _json = string(abi.encodePacked(
                "Player ", _metadata.farmer.name, 
                " helped ", lookupRanchName(_metadata.farmer.ranchId),
                " rank as #", _metadata.tokenInfo.award.ranking.toString(),
                " ", _metadata.tokenInfo.award.category.toString()
            ));
        } else {
            _json = string(abi.encodePacked(
                "Player ", _metadata.farmer.name,
                " helped ", _metadata.bufficorn.name,
                " rank as #", _metadata.tokenInfo.award.ranking.toString(),
                " ", _metadata.tokenInfo.award.category.toString()
            ));
        }
    }

    function _loadAttributes(
           bytes32 _randomness,
           WittyBufficornsLib.TokenMetadata memory _metadata
        )
        internal view
        returns (string memory _json)
    {
        _json = _loadAttributesCommon(_metadata);
        WittyBufficornsLib.Awards _category = _metadata.tokenInfo.award.category;
        if (_category == WittyBufficornsLib.Awards.BestBreeder) {
            _json = string(abi.encodePacked(
                _json,
                _loadAttributesFarmer(
                    _randomness,
                    _metadata.tokenInfo.award.ranking,
                    _metadata.farmer
                )
            ));
        } else if (_category == WittyBufficornsLib.Awards.BestRanch) {
            _json = string(abi.encodePacked(
                _json,
                _loadAttributesRanch(
                    _metadata.tokenInfo.award.ranking,
                    _metadata.farmer.ranchId,
                    _metadata.ranch
                )
            ));
        } else {
            _json = string(abi.encodePacked(
                _json,
                _loadAttributesBufficorn(
                    _metadata.tokenInfo.award.ranking,
                    _metadata.bufficorn
                )
            ));
        }
    }

    function _loadAttributesCommon(WittyBufficornsLib.TokenMetadata memory _metadata)
        internal pure
        returns (string memory)
    {
        string memory _awardCategoryTrait = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Award Category\",",
                "\"value\": \"", _metadata.tokenInfo.award.category.toString(), "\"",
            "},"
        ));
        string memory _expeditionDateTrait = string(abi.encodePacked(
             "{",
                "\"display_type\": \"date\",",
                "\"trait_type\": \"Expedition Date\",",
                "\"value\": ", _metadata.tokenInfo.expeditionTs.toString(),
            "},"
        ));
        string memory _medalTrait = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Medal\",",
                "\"value\": \"", lookupMedalCaption(_metadata.tokenInfo.award.ranking), "\"",
            "},"
        ));
        string memory _farmerNameTrait = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Farmer Name\",",
                "\"value\": \"", _metadata.farmer.name, "\""
            "},"
        ));
        return string(abi.encodePacked(
            _awardCategoryTrait,
            _expeditionDateTrait,
            _medalTrait,
            _farmerNameTrait
        ));
    }

    function _loadAttributesFarmer(
            bytes32 _randomness,
            uint256 _ranking,
            WittyBufficornsLib.Farmer memory _farmer
        )
        internal view
        returns (string memory _json)
    {
        _json = string(abi.encodePacked(
            "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Farmer Ranking\",",
                "\"value\": ", _ranking.toString(),
            "},"
            "{", 
                "\"trait_type\": \"Farmer Score\",",
                "\"value\": ", _farmer.score.toString(),
            "}"
        ));
        uint8 _ranchId = uint8(_farmer.ranchId);
        uint32 _randomRange = boosters.range;
        for (
            uint8 _traitIndex = 0;
            _traitIndex < uint8(type(WittyBufficornsLib.Traits).max) + 1;
            _traitIndex ++
        ) {
            uint _traitBoost = 0;
            if (_traitIndex == _ranchId) {
                _traitBoost = (
                    _ranking < 100
                        ? 100 - (25 * (_ranking / 25))
                        : 10
                );
            } else if (_randomness != bytes32(0) && _randomRange > 0) {
                _traitBoost = _getRandomTraitBoost(
                    _randomRange,
                    _traitIndex,
                    _randomness
                );
            }          
            if (_traitBoost > 0) {
                _json = string(abi.encodePacked(
                    _json,
                    ",{",
                        "\"display_type\": \"boost_percentage\",",
                        "\"trait_type\": \"", lookupRanchResource(_traitIndex), " Increase\",",
                        "\"value\": ", _traitBoost.toString(),
                    "}"
                ));
            }
        }
    }

    function _loadAttributesRanch(
            uint256 _ranking,
            uint256 _ranchId,
            WittyBufficornsLib.Ranch memory _ranch
        )
        internal pure
        returns (string memory)
    {
        string memory _ranchDateTrait = string(abi.encodePacked(
            "{",
                "\"display_type\": \"date\",",
                "\"trait_type\": \"Ranch Date\",",
                "\"value\": ", _ranch.weatherTimestamp.toString(),
            "},"
        ));
        string memory _ranchNameTrait = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Ranch Name\",",
                "\"value\": \"", lookupRanchName(_ranchId), "\""
            "},"
        ));
        string memory _ranchRanking =string(abi.encodePacked(
            "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Ranch Ranking\",",
                "\"value\": ", _ranking.toString(),
            "},"
        ));
        string memory _ranchScore = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Ranch Score\",",
                "\"value\": ", _ranch.score.toString(),
            "},"
        ));
        string memory _ranchWeatherTrait = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Ranch Weather\",",
                "\"value\": \"", _ranch.weatherDescription, "\""
            "}"
        ));
        return string(abi.encodePacked(
            _ranchDateTrait,
            _ranchNameTrait,
            _ranchRanking,
            _ranchScore,
            _ranchWeatherTrait
        ));
    }

    function _loadAttributesBufficorn(
            uint256 _ranking,
            WittyBufficornsLib.Bufficorn memory _bufficorn
        )
        internal pure
        returns (string memory)
    {
        string memory _bufficornNameTrait = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Bufficorn Name\",",
                "\"value\": \"", _bufficorn.name, "\""
            "},"
        ));
        string memory _bufficornRankingTrait = string(abi.encodePacked(
            "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Bufficorn Ranking\",",
                "\"value\": \"", _ranking.toString(), "\""
            "},"
        ));
        string memory _bufficornScoreTrait = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Bufficorn Score\",",
                "\"value\": ", _bufficorn.score.toString(),
            "}"
        ));
        string memory _bufficornTraits;
        for (uint8 _traitIndex = 0; _traitIndex < 6; _traitIndex ++) {
            string memory _traitName = WittyBufficornsLib.Traits(_traitIndex).toString();
            string memory _traitValue = _bufficorn.traits[_traitIndex].toString();
            _bufficornTraits = string(abi.encodePacked(
                _bufficornTraits,
                ",{",
                    "\"trait_type\": \"Bufficorn ", _traitName, "\",",
                    "\"value\": ", _traitValue,
                "}"
            ));
        }
        return string(abi.encodePacked(
            _bufficornNameTrait,
            _bufficornRankingTrait,
            _bufficornScoreTrait,
            _bufficornTraits
        ));
    }
}