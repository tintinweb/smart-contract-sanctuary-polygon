// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WitnetRequestBoard.sol";

/// @title WittyBufficornsLib Library: data model and helper functions
/// @author Otherplane Labs, 2022.
library WittyBufficornsLib {

    // ========================================================================
    // --- Storage layout -----------------------------------------------------

    struct Storage {
        address decorator;
        address signator;

        Stats   stats;

        uint256 stopBreedingBlock;
        bytes32 stopBreedingRandomness;
        
        mapping (/* tokenId => FarmerAward */ uint256 => TokenInfo) awards;
        mapping (/* bufficornId => Bufficorn */ uint256 => Bufficorn) bufficorns;
        mapping (/* farmerId => Farmer */ uint256 => Farmer) farmers;
        mapping (/* ranchId => Ranch */ uint256 => Ranch) ranches;
    }


    // ========================================================================
    // --- Enums --------------------------------------------------------------

    enum Awards {
        /* 0 => */ BestBreeder,
        /* 1 => */ BestRanch,

        /* 2 => */ BestBufficorn,

        /* 3 => */ WarmestBufficorn,
        /* 4 => */ CoolestBufficorn,
        /* 5 => */ SmartestBufficorn,      
        /* 6 => */ FastestBufficorn,
        /* 7 => */ MostEnduringBufficorn,
        /* 8 => */ MostVigorousBufficorn
    }

    enum Status {
        /* 0 => */ Breeding,
        /* 1 => */ Randomizing,
        /* 2 => */ Awarding
    }

    enum Traits {
        /* 0 => */ Coat, 
        /* 1 => */ Coolness,
        /* 2 => */ Intelligence,
        /* 3 => */ Speed,
        /* 4 => */ Stamina,
        /* 5 => */ Strength
    }
    

    // ========================================================================
    // --- Structs ------------------------------------------------------------

    struct Award {
        Awards  category;
        uint256 ranking;
        uint256 bufficornId;
    }

    struct Bufficorn {
        string name;
        uint256 score;
        uint256 ranchId;
        uint256[6] traits;
    }

    struct Farmer {
        string  name;
        uint256 score;
        uint256 ranchId;
        uint256 firstTokenId;
        uint256 totalAwards;
    }

    struct Ranch {
        uint256 score;
        string  weatherDescription;
        bytes4  weatherStation;
        uint256 weatherTimestamp;
        WitnetInfo witnet;
    }

    struct Stats {
        uint256 totalBufficorns;
        uint256 totalFarmers;
        uint256 totalRanches;
        uint256 totalSupply;
    }
    
    struct TokenInfo {
        Award   award;
        uint256 farmerId;  
        uint256 expeditionTs;
    }

    struct WitnetInfo {
        uint256 lastValidQueryId;
        uint256 latestQueryId;
        IWitnetRequest request;
    }

    struct TokenMetadata {
        TokenInfo tokenInfo;
        Farmer farmer;
        Ranch ranch;
        Bufficorn bufficorn;
    }


    // ========================================================================
    // --- Public: 'Storage' selectors ----------------------------------------

    function status(Storage storage self)
        public view
        returns (Status)
    {
        if (self.stopBreedingRandomness != bytes32(0)) {
            return Status.Awarding;
        } else if (self.stopBreedingBlock > 0) {
            return Status.Randomizing;
        } else {
            return Status.Breeding;
        }
    }

    function getRanchWeather(
            Storage storage self,
            WitnetRequestBoard _wrb,
            uint256 _ranchId
        )
        public view
        returns (
            uint256 _lastTimestamp,
            string memory _lastDescription
        )
    {
        Ranch storage __ranch = self.ranches[_ranchId];
        uint _lastValidQueryId = __ranch.witnet.lastValidQueryId;
        uint _latestQueryId = __ranch.witnet.latestQueryId;
        Witnet.QueryStatus _latestQueryStatus = _wrb.getQueryStatus(_latestQueryId);
        Witnet.Response memory _response;
        Witnet.Result memory _result;
        // First try to read weather from latest request, in case it was succesfully solved:
        if (_latestQueryId > 0 && _latestQueryStatus == Witnet.QueryStatus.Reported) {
            _response = _wrb.readResponse(_latestQueryId);
            _result = _wrb.resultFromCborBytes(_response.cborBytes);
            if (_result.success) {
                return (
                    _response.timestamp,
                    _wrb.asString(_result)
                );
            }
        }
        if (_lastValidQueryId > 0) {
            // If not solved, or solved with errors, read weather from last valid request, if any:
            _response = _wrb.readResponse(_lastValidQueryId);
            _result = _wrb.resultFromCborBytes(_response.cborBytes);
            _lastTimestamp = _response.timestamp;
            _lastDescription = _wrb.asString(_result);
        }
    }

    function updateRanchWeather(
            Storage storage self,
            WitnetRequestBoard _wrb,
            uint256 _ranchId
        )
        public 
        returns (uint256 _usedFunds)
    {
        Ranch storage __ranch = self.ranches[_ranchId];
        if (address(__ranch.witnet.request) != address(0)) {
            uint _lastValidQueryId = __ranch.witnet.lastValidQueryId;
            uint _latestQueryId = __ranch.witnet.latestQueryId;            
            // Check whether there's no previous request pending to be solved:
            Witnet.QueryStatus _latestQueryStatus = _wrb.getQueryStatus(_latestQueryId);
            if (_latestQueryId == 0 || _latestQueryStatus != Witnet.QueryStatus.Posted) {
                if (_latestQueryId > 0 && _latestQueryStatus == Witnet.QueryStatus.Reported) {
                    Witnet.Result memory _latestResult  = _wrb.readResponseResult(_latestQueryId);
                    if (_latestResult.success) {
                        // If latest request was solved with no errors...
                        if (_lastValidQueryId > 0) {
                            // ... delete last valid response, if any
                            _wrb.deleteQuery(_lastValidQueryId);
                        }
                        // ... and set latest request id as last valid request id.
                        __ranch.witnet.lastValidQueryId = _latestQueryId;
                    }
                }
                // Estimate request fee, in native currency:
                _usedFunds = _wrb.estimateReward(tx.gasprice);
                
                // Post weather update request to the WitnetRequestBoard contract:
                __ranch.witnet.latestQueryId = _wrb.postRequest{value: _usedFunds}(__ranch.witnet.request);
                
                if (_usedFunds < msg.value) {
                    // Transfer back unused funds, if any:
                    payable(msg.sender).transfer(msg.value - _usedFunds);
                }
            }
        }
    }


    // ========================================================================
    // --- Public: 'Awards' selectors ------------------------------------------

    function toString(Awards self)
        public pure
        returns (string memory)
    {
        if (self == Awards.BestBufficorn) {
            return "Best Overall Bufficorn";
        } else if (self == Awards.WarmestBufficorn) {
            return "Warmest Bufficorn";
        } else if (self == Awards.CoolestBufficorn) {
            return "Coolest Bufficorn";
        } else if (self == Awards.SmartestBufficorn) {
            return "Smartest Bufficorn";
        } else if (self == Awards.FastestBufficorn) {
            return "Fastest Bufficorn";
        } else if (self == Awards.MostEnduringBufficorn) {
            return "Most Enduring Bufficorn";
        } else if (self == Awards.MostVigorousBufficorn) {
            return "Most Vigorous Bufficorn";
        } else if (self == Awards.BestRanch) {
            return "Best Ranch";
        } else {
            return "Best Breeder";
        }
    }


    // ========================================================================
    // --- Public: 'Traits' selectors -----------------------------------------

    function toString(Traits self)
        public pure
        returns (string memory)
    {
        if (self == Traits.Coat) {
            return "Coat";
        } else if (self == Traits.Coolness) {
            return "Coolness";
        } else if (self == Traits.Intelligence) {
            return "Intelligence";
        } else if (self == Traits.Speed) {
            return "Speed";
        } else if (self == Traits.Stamina) {
            return "Stamina";
        } else {
            return "Strength";
        }
    }
    

    // ========================================================================
    // --- Internal/public helper functions -----------------------------------

    /// Generates a pseudo-random number uniformly distributed within the range [0 .. _range), by using 
    /// the given `_nonce` value and the given `_seed` as a source of entropy.
    /// @param _range Range within which the uniformly-distributed random number will be generated.
    /// @param _nonce Nonce value enabling multiple random numbers from the same randomness value.
    /// @param _seed Seed value used as entropy source.
    function random(uint32 _range, uint256 _nonce, bytes32 _seed)
        public pure
        returns (uint32)
    {
        uint8 _flagBits = uint8(255 - _msbDeBruijn32(_range));
        uint256 _number = uint256(
                keccak256(
                    abi.encode(_seed, _nonce)
                )
            ) & uint256(2 ** _flagBits - 1);
        return uint32((_number * _range) >> _flagBits);
    }

    /// Recovers address from hash and signature.
    function recoverAddr(bytes32 _hash, bytes memory _signature)
        internal pure
        returns (address)
    {
        if (_signature.length != 65) {
            return (address(0));
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        if (v != 27 && v != 28) {
            return address(0);
        }
        return ecrecover(_hash, v, r, s);
    }


    // ========================================================================
    // --- PRIVATE FUNCTIONS --------------------------------------------------

    /// @dev Returns index of the Most Significant Bit of the given number, applying De Bruijn O(1) algorithm.
    function _msbDeBruijn32(uint32 _v)
        private pure
        returns (uint8)
    {
        uint8[32] memory _bitPosition = [
                0, 9, 1, 10, 13, 21, 2, 29,
                11, 14, 16, 18, 22, 25, 3, 30,
                8, 12, 20, 28, 15, 17, 24, 7,
                19, 27, 23, 6, 26, 5, 4, 31
            ];
        _v |= _v >> 1;
        _v |= _v >> 2;
        _v |= _v >> 4;
        _v |= _v >> 8;
        _v |= _v >> 16;
        return _bitPosition[
            uint32(_v * uint256(0x07c4acdd)) >> 27
        ];
    }
}