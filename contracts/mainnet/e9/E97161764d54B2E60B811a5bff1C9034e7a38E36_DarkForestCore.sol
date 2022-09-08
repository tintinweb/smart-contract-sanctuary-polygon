// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

// Import base Initializable contract
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "./Verifier.sol";
import "./DarkForestStorageV1.sol";
import "./DarkForestUtils.sol";
import "./DarkForestPlanet.sol";
import "./DarkForestLazyUpdate.sol";
import "./DarkForestInitialize.sol";

// .______       _______     ___       _______  .___  ___.  _______
// |   _  \     |   ____|   /   \     |       \ |   \/   | |   ____|
// |  |_)  |    |  |__     /  ^  \    |  .--.  ||  \  /  | |  |__
// |      /     |   __|   /  /_\  \   |  |  |  ||  |\/|  | |   __|
// |  |\  \----.|  |____ /  _____  \  |  '--'  ||  |  |  | |  |____
// | _| `._____||_______/__/     \__\ |_______/ |__|  |__| |_______|
//
// READ THIS FIRST BEFORE EDITING ANYTHING IN THIS FILE:
// https://docs.openzeppelin.com/learn/upgrading-smart-contracts#limitations-of-contract-upgrades
//
// DO NOT ADD ANY STORAGE VARIABLES IN THIS FILE
// IT SHOULD BELONG AT STORAGE CONTRACTS
// ADDING STORAGE VARIABLES HERE WI LL BLOCK ANY STORAGE CONTRACTS FROM EVER
// ADDING THEIR OWN VARIABLES EVER AGAIN.

contract DarkForestCore is Initializable, DarkForestStorageV1 {
    using ABDKMath64x64 for *;
    using SafeMath for *;
    using Math for uint256;

    event PlayerInitialized(address player, uint256 loc);
    event ArrivalQueued(uint256 arrivalId);
    event PlanetUpgraded(uint256 loc);

    function initialize(
        address _adminAddress,
        address _whitelistAddress,
        bool _disableZKCheck
    ) public initializer {
        adminAddress = _adminAddress;
        whitelist = Whitelist(_whitelistAddress);

        paused = false;

        VERSION = 1;
        DISABLE_ZK_CHECK = _disableZKCheck;

        gameEndTimestamp = 1697464000;
        target4RadiusConstant = 50;
        target5RadiusConstant = 12;

        planetTypeThresholds = [65536, 0];
        planetLevelThresholds = [
            16777216,
            4194256,
            1048516,
            262081,
            65472,
            16320,
            4032,
            960
        ];

        DarkForestInitialize.initializeDefaults(planetDefaultStats);
        DarkForestInitialize.initializeUpgrades(upgrades);

        initializedPlanetCountByLevel = [0, 0, 0, 0, 0, 0, 0, 0];
        for (uint256 i = 0; i < planetLevelThresholds.length; i += 1) {
            cumulativeRarities.push(
                (2**24 / planetLevelThresholds[i]) * PLANET_RARITY
            );
        }

        _updateWorldRadius();
    }

    //////////////////////
    /// ACCESS CONTROL ///
    //////////////////////
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Sender is not a game master");
        _;
    }

    modifier onlyWhitelisted() {
        require(
            whitelist.isWhitelisted(msg.sender),
            "Player is not whitelisted"
        );
        _;
    }

    modifier notPaused() {
        require(!paused, "Game is paused");
        _;
    }

    modifier notEnded() {
        require(block.timestamp < gameEndTimestamp, "Game have ended");
        _;
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "newOwner cannot be 0x0");
        adminAddress = _newAdmin;
    }

    /////////////////////////////
    /// Administrative Engine ///
    /////////////////////////////
    function pause() public onlyAdmin {
        require(!paused, "Game is already paused");
        paused = true;
    }

    function unpause() public onlyAdmin {
        require(paused, "Game is already unpaused");
        paused = false;
    }

    function changeGameEndTime(uint256 _newGameEnd) public onlyAdmin {
        gameEndTimestamp = _newGameEnd;
    }

    function changeTarget4RadiusConstant(uint256 _newConstant)
        public
        onlyAdmin
    {
        target4RadiusConstant = _newConstant;
    }

    function changeTarget5RadiusConstant(uint256 _newConstant)
        public
        onlyAdmin
    {
        target5RadiusConstant = _newConstant;
    }

    //////////////
    /// Helper ///
    //////////////

    // Public helper getters
    function getNPlanets() public view returns (uint256) {
        return planetIds.length;
    }

    function bulkGetPlanetIds(uint256 startIdx, uint256 endIdx)
        public
        view
        returns (uint256[] memory ret)
    {
        // return slice of planetIds array from startIdx through endIdx - 1
        ret = new uint256[](endIdx - startIdx);
        for (uint256 i = startIdx; i < endIdx; i++) {
            ret[i - startIdx] = planetIds[i];
        }
    }

    function bulkGetPlanets(uint256 startIdx, uint256 endIdx)
        public
        view
        returns (DarkForestTypes.Planet[] memory ret)
    {
        // return array of planets corresponding to planetIds[startIdx] through planetIds[endIdx - 1]
        ret = new DarkForestTypes.Planet[](endIdx - startIdx);
        for (uint256 i = startIdx; i < endIdx; i++) {
            ret[i - startIdx] = planets[planetIds[i]];
        }
    }

    function bulkGetPlanetsExtendedInfo(uint256 startIdx, uint256 endIdx)
        public
        view
        returns (DarkForestTypes.PlanetExtendedInfo[] memory ret)
    {
        // return array of planets corresponding to planetIds[startIdx] through planetIds[endIdx - 1]
        ret = new DarkForestTypes.PlanetExtendedInfo[](endIdx - startIdx);
        for (uint256 i = startIdx; i < endIdx; i++) {
            ret[i - startIdx] = planetsExtendedInfo[planetIds[i]];
        }
    }

    function getNPlayers() public view returns (uint256) {
        return playerIds.length;
    }

    function bulkGetPlayers(uint256 startIdx, uint256 endIdx)
        public
        view
        returns (address[] memory ret)
    {
        // return slice of players array from startIdx through endIdx - 1
        ret = new address[](endIdx - startIdx);
        for (uint256 i = startIdx; i < endIdx; i++) {
            ret[i - startIdx] = playerIds[i];
        }
    }

    function getPlanetLevelThresholds() public view returns (uint256[] memory) {
        return planetLevelThresholds;
    }

    function getPlanetTypeThresholds() public view returns (uint256[] memory) {
        return planetTypeThresholds;
    }

    function getPlanetCumulativeRarities()
        public
        view
        returns (uint256[] memory)
    {
        return cumulativeRarities;
    }

    function getPlanetArrivals(uint256 _location)
        public
        view
        returns (DarkForestTypes.ArrivalData[] memory ret)
    {
        uint256 arrivalCount = 0;
        for (uint256 i = 0; i < planetEvents[_location].length; i += 1) {
            if (
                planetEvents[_location][i].eventType ==
                DarkForestTypes.PlanetEventType.ARRIVAL
            ) {
                arrivalCount += 1;
            }
        }
        ret = new DarkForestTypes.ArrivalData[](arrivalCount);
        uint256 count = 0;
        for (uint256 i = 0; i < planetEvents[_location].length; i += 1) {
            if (
                planetEvents[_location][i].eventType ==
                DarkForestTypes.PlanetEventType.ARRIVAL
            ) {
                ret[count] = planetArrivals[planetEvents[_location][i].id];
                count++;
            }
        }
    }

    function bulkGetPlanetArrivals(uint256 startIdx, uint256 endIdx)
        public
        view
        returns (DarkForestTypes.ArrivalData[][] memory)
    {
        // return array of planets corresponding to planetIds[startIdx] through planetIds[endIdx - 1]


            DarkForestTypes.ArrivalData[][] memory ret
         = new DarkForestTypes.ArrivalData[][](endIdx - startIdx);
        for (uint256 i = startIdx; i < endIdx; i++) {
            ret[i - startIdx] = getPlanetArrivals(planetIds[i]);
        }
        return ret;
    }

    function getDefaultStats()
        public
        view
        returns (DarkForestTypes.PlanetDefaultStats[] memory)
    {

            DarkForestTypes.PlanetDefaultStats[] memory ret
         = new DarkForestTypes.PlanetDefaultStats[](
            planetLevelThresholds.length
        );
        for (uint256 i = 0; i < planetLevelThresholds.length; i += 1) {
            ret[i] = planetDefaultStats[i];
        }
        return ret;
    }

    function getPlanetCounts() public view returns (uint256[] memory) {
        return initializedPlanetCountByLevel;
    }

    function getUpgrades()
        public
        view
        returns (DarkForestTypes.Upgrade[4][3] memory)
    {
        return upgrades;
    }

    // private utilities

    function _getPlanetType()
        public
        pure
        returns (
            /* uint256 _location */
            DarkForestTypes.PlanetType
        )
    {
        return DarkForestTypes.PlanetType.PLANET;
    }

    function _locationIdValid(uint256 _loc) public pure returns (bool) {
        return (_loc <
            (21888242871839275222246405745257275088548364400416034343698204186575808495617 /
                PLANET_RARITY));
    }

    // Private helpers that modify state
    function _updateWorldRadius() private {
        worldRadius = DarkForestUtils._getRadius(
            initializedPlanetCountByLevel,
            cumulativeRarities,
            playerIds.length,
            target4RadiusConstant,
            target5RadiusConstant
        );
    }

    function _initializePlanet(uint256 _location, bool _isHomePlanet) private {
        require(_locationIdValid(_location), "Not a valid planet location");

        (
            uint256 _level,
            DarkForestTypes.PlanetResource _resource
        ) = DarkForestUtils._getPlanetLevelAndResource(
            _location,
            SILVER_RARITY,
            planetLevelThresholds,
            planetDefaultStats
        );

        DarkForestTypes.PlanetType _type = _getPlanetType();

        if (_isHomePlanet) {
            require(_level == 0, "Can only initialize on planet level 0");
        }

        DarkForestPlanet.initializePlanet(
            planets[_location],
            planetsExtendedInfo[_location],
            planetDefaultStats[_level],
            VERSION,
            _type,
            _resource,
            _level,
            _location
        );
        planetIds.push(_location);
        initializedPlanetCountByLevel[_level] += 1;
    }

    //////////////////////
    /// Game Mechanics ///
    //////////////////////

    function refreshPlanet(uint256 _location)
        public
        onlyWhitelisted
        notPaused
        notEnded
    {
        require(
            planetsExtendedInfo[_location].isInitialized,
            "Planet has not been initialized"
        );

        // apply all pending events until the current timestamp
        DarkForestLazyUpdate._applyPendingEvents(
            _location,
            planetEvents,
            planets,
            planetsExtendedInfo,
            planetArrivals
        );

        // we need to do another updatePlanet call to sync the planet's data
        // to current time.
        DarkForestLazyUpdate.updatePlanet(
            planets[_location],
            planetsExtendedInfo[_location],
            block.timestamp
        );
    }

    function initializePlayer(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[3] memory _input
    ) public onlyWhitelisted notPaused notEnded {
        if (!DISABLE_ZK_CHECK) {
            require(
                Verifier.verifyInitProof(_a, _b, _c, _input),
                "Failed init proof check"
            );
        }

        uint256 _location = _input[0];
        // uint256 _perlin = _input[1];
        uint256 _radius = _input[2];

        require(
            !isPlayerInitialized[msg.sender],
            "Player is already initialized"
        );
        require(
            !planetsExtendedInfo[_location].isInitialized,
            "Planet is already initialized"
        );
        require(
            _radius <= worldRadius,
            "Init radius is bigger than the current world radius"
        );
        // require(
        //     _perlin <= PERLIN_THRESHOLD,
        //     "Init not allowed in perlin value above the threshold"
        // );

        // Initialize player data
        isPlayerInitialized[msg.sender] = true;
        playerIds.push(msg.sender);

        // Initialize planet information
        _initializePlanet(_location, true);
        planets[_location].owner = msg.sender;
        planets[_location].population = 75000;
        _updateWorldRadius();
        emit PlayerInitialized(msg.sender, _location);
    }

    function move(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[7] memory _input
    ) public notPaused notEnded {
        uint256 _oldLoc = _input[0];
        uint256 _newLoc = _input[1];
        uint256 _newPerlin = _input[2];
        uint256 _newRadius = _input[3];
        uint256 _maxDist = _input[4];
        uint256 _popMoved = _input[5];
        uint256 _silverMoved = _input[6];

        if (!DISABLE_ZK_CHECK) {
            uint256[5] memory _proofInput = [
                _oldLoc,
                _newLoc,
                _newPerlin,
                _newRadius,
                _maxDist
            ];
            require(
                Verifier.verifyMoveProof(_a, _b, _c, _proofInput),
                "Failed move proof check"
            );
        }

        // check radius
        require(_newRadius <= worldRadius, "Attempting to move out of bounds");

        // Only perform if the toPlanet have never initialized previously
        if (!planetsExtendedInfo[_newLoc].isInitialized) {
            _initializePlanet(_newLoc, false);
        } else {
            // need to do this so people can't deny service to their own planets with gas limit
            refreshPlanet(_newLoc);
            require(planetEvents[_newLoc].length < 8, "Planet is rate-limited");
        }

        // Refresh fromPlanet first before doing any action on it
        refreshPlanet(_oldLoc);
        DarkForestPlanet.move(
            _oldLoc,
            _newLoc,
            _maxDist,
            _popMoved,
            _silverMoved,
            GLOBAL_SPEED_IN_HUNDRETHS,
            planetEventsCount,
            planets,
            planetEvents,
            planetArrivals
        );

        planetEventsCount++;

        _updateWorldRadius();
        emit ArrivalQueued(planetEventsCount - 1);
    }

    function upgradePlanet(uint256 _location, uint256 _branch)
        public
        notPaused
        notEnded
    {
        // _branch specifies which of the three upgrade branches player is leveling up
        // 0 improves silver production and capacity
        // 1 improves population
        // 2 improves range
        refreshPlanet(_location);
        DarkForestPlanet.upgradePlanet(
            planets[_location],
            planetsExtendedInfo[_location],
            _branch,
            planetDefaultStats,
            upgrades
        );
        emit PlanetUpgraded(_location);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// Import base Initializable contract
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

contract Whitelist is Initializable {
    bool whitelistEnabled;
    mapping(address => bool) allowedAccounts;
    mapping(bytes32 => bool) allowedKeyHashes;
    address[] allowedAccountsArray;
    address admin;

    // administrative
    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Only administrator can perform this action"
        );
        _;
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function initialize(address _admin, bool _whitelistEnabled)
        public
        initializer
    {
        admin = _admin;
        whitelistEnabled = _whitelistEnabled;
    }

    // public getters
    function getNAllowed() public view returns (uint256) {
        return allowedAccountsArray.length;
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        if (!whitelistEnabled) {
            return true;
        }
        return allowedAccounts[_addr];
    }

    function isKeyValid(string memory key) public view returns (bool) {
        bytes32 hashed = keccak256(abi.encodePacked(key));
        return allowedKeyHashes[hashed];
    }

    // modify whitelist
    function addKeys(bytes32[] memory hashes) public onlyAdmin {
        for (uint16 i = 0; i < hashes.length; i++) {
            allowedKeyHashes[hashes[i]] = true;
        }
    }

    function useKey(string memory key, address owner) public onlyAdmin {
        require(!allowedAccounts[owner], "player already whitelisted");
        bytes32 hashed = keccak256(abi.encodePacked(key));
        require(allowedKeyHashes[hashed], "invalid key");
        allowedAccounts[owner] = true;
        allowedAccountsArray.push(owner);
        allowedKeyHashes[hashed] = false;
    }

    function removeFromWhitelist(address toRemove) public onlyAdmin {
        require(
            allowedAccounts[toRemove],
            "player was not whitelisted to begin with"
        );
        allowedAccounts[toRemove] = false;
        for (uint256 i = 0; i < allowedAccountsArray.length; i++) {
            if (allowedAccountsArray[i] == toRemove) {
                allowedAccountsArray[i] = allowedAccountsArray[allowedAccountsArray
                    .length - 1];
                allowedAccountsArray.pop();
            }
        }
    }
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.5
//      fixed linter warnings
//      added requiere error messages
//
pragma solidity ^0.6.9;

library Pairing {
    struct G1Point {
        uint256 X;
        uint256 Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return
            G2Point(
                [
                    11559732032986387107991004021392285783925812861821192530917403151452391805634,
                    10857046999023057135944570762232829481370756359578518086990519993285655852781
                ],
                [
                    4082367875863433681332203403145435568316851327593401208105741076214120093531,
                    8495653923123431417604973247489272438418190587263600148770280649306958101930
                ]
            );

        /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }

    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }

    /// return the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
                case 0 {
                    invalid()
                }
        }
        require(success, "pairing-add-failed");
    }

    /// return the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
                case 0 {
                    invalid()
                }
        }
        require(success, "pairing-mul-failed");
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length, "pairing-lengths-failed");
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
                case 0 {
                    invalid()
                }
        }
        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

library Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function initVerifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(7281105078913742442296235834977471874958451417120828887701980407544612553243,19595542660900081245584797582057060524038302747944931422262252806492756080553);
        vk.beta2 = Pairing.G2Point([7808193876135014909947403445469956517473532195818313522167220384789355156669,18656821286637803579468149555012067875381309884750289970292212673500972214616], [6854695953384886892320218710899793461012304698569828807746319233576269691464,13590642774160222856500614724887185604712630217377756928084542148613381938611]);
        vk.gamma2 = Pairing.G2Point([21050640004270530753007884243471807315401389932278336285551359189537788962999,15005198638066965175333714762431535463592917192883402620302502881536388626348], [7335530020413117059570806629770139926087494608289524815569899109101194381068,431400724710951445651474643705038817371627542871370137193344775108346516739]);
        vk.delta2 = Pairing.G2Point([1588252115427901895522108580843401579234316208232630328660779981840095001913,8834632793911083620568722933812045054963121111041592915470927334257202620202], [7300751374727903594677648636731025663755556368639742221847591087281527965122,7455373947704397881096301814381245237021164589824962357289994065370058121092]);
        vk.IC = new Pairing.G1Point[](4);
        vk.IC[0] = Pairing.G1Point(18874201358466661179403078356464904509530143100871531128761221831718680079502,10698310398678785052611881216377462638009891358931835035979860608425531909796);
        vk.IC[1] = Pairing.G1Point(19307773701003041250530899033991114617041289078623455118864903807626045408178,4755521348080295284610243333221356066751456494691626996232081065289002083733);
        vk.IC[2] = Pairing.G1Point(14363077663269982943106571140122877146647198266843222839597616419177248521342,10969767172141370545919576345243140069108063735217455909277827155250618575380);
        vk.IC[3] = Pairing.G1Point(10623494663628425976001684986759859919567313415533900942692177711494257383638,1330253113995527435745913788261805321855302276067439966186055717560053861773);
}

    function moveVerifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(12356802866449684997754107026347724953200774039678274471013975138517593361087,21147804457019395991806869559397462101175520127921542208311373203012833194601);
        vk.beta2 = Pairing.G2Point([20312436584921143996382367775395050029037126489576390051832424712464633156881,15808958171969166309350067434410880068685601765078930692701835659651547482842], [11841408325541200734034253864958381613260236318165289062766853151562613702905,9008008905525251120175076460731597382202744275427804476364024531090012620564]);
        vk.gamma2 = Pairing.G2Point([11361795804780224978844178001925729689650024058711422666157584535385144431705,7122013203828801274422153445030402003881969525105563481484708347337413201538], [5002285043841389455832994040165569944922238258053153530287333974352125021902,20096615172017458085651599655933948938448025857163979534957128223939618198388]);
        vk.delta2 = Pairing.G2Point([8232217592337110330679426534589513839782865123649121485999683802146395728986,523054318759045886270478616254946240625318844591509494535337822553965419812], [4775559301227633713252197493351530092469029275309412496189875893005909128344,18308456029233847815432487462880449809684697385055594585677517361167895152523]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(5137757912911425606111596161256428319175968695746466094372617689727883934476,16947946068729419285709126507628073529337421739971475956480754903096508265527);
        vk.IC[1] = Pairing.G1Point(12579634223583854130962938841109141174899560596507357021188528481766728424450,20525055772249706643897653591342282874821822793792227510348605834653297945682);
        vk.IC[2] = Pairing.G1Point(14622227896628130111052972056837140629321300430578590306328210813525830072328,6184833258955319070536885489455869985346738032641561420359557770756648976828);
        vk.IC[3] = Pairing.G1Point(16066947475381981290744201544908693647123066648401692774090893152870028461573,10771769201246879183931872929279706856164311318494670331707717089024576077594);
        vk.IC[4] = Pairing.G1Point(12610108600517026896705631215189062744819841027302360627680860843541213513408,11288659798374481219360116219410436830823818049675377774842959008385292732179);
        vk.IC[5] = Pairing.G1Point(15049428532631936537505424841304033088208616239552421553261584779111819398267,10555418485704636736423712433298028713772103788953598601644039199059490897251);
}

    function verify(
        uint256[] memory input,
        Proof memory proof,
        VerifyingKey memory vk
    ) internal view returns (uint256) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input,
        VerifyingKey memory vk
    ) internal view returns (bool) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        if (verify(input, proof, vk) == 0) {
            return true;
        } else {
            return false;
        }
    }

    function verifyInitProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) public view returns (bool) {
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        return verifyProof(a, b, c, inputValues, initVerifyingKey());
    }

    function verifyMoveProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input
    ) public view returns (bool) {
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        return verifyProof(a, b, c, inputValues, moveVerifyingKey());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

// Libraries
import "./ABDKMath64x64.sol";
import "./DarkForestTypes.sol";

library DarkForestUtils {
    function _calculateByteUInt(
        bytes memory _b,
        uint256 _startByte,
        uint256 _endByte
    ) public pure returns (uint256 _byteUInt) {
        for (uint256 i = _startByte; i <= _endByte; i++) {
            _byteUInt += uint256(uint8(_b[i])) * (256**(_endByte - i));
        }
    }

    function _getPlanetLevelAndResource(
        uint256 _location,
        uint256 SILVER_RARITY,
        uint256[] storage planetLevelThresholds,
        DarkForestTypes.PlanetDefaultStats[] storage planetDefaultStats
    ) public view returns (uint256, DarkForestTypes.PlanetResource) {
        bytes memory _b = abi.encodePacked(_location);

        // get the uint value of byte 4 - 6
        uint256 _planetLevelUInt = _calculateByteUInt(_b, 4, 6);
        uint256 level;

        // reverse-iterate thresholds and return planet type accordingly
        for (uint256 i = (planetLevelThresholds.length - 1); i >= 0; i--) {
            if (_planetLevelUInt < planetLevelThresholds[i]) {
                level = i;
                break;
            }
        }

        DarkForestTypes.PlanetResource resource;

        if (
            planetDefaultStats[level].silverGrowth > 0 &&
            uint256(uint8(_b[10])) * SILVER_RARITY < 256
        ) {
            resource = DarkForestTypes.PlanetResource.SILVER;
        } else {
            resource = DarkForestTypes.PlanetResource.NONE;
        }

        return (level, resource);
    }

    function _getRadius(
        uint256[] storage initializedPlanetCountByLevel,
        uint256[] storage cumulativeRarities,
        uint256 nPlayers,
        uint256 target4RadiusConstant,
        uint256 target5RadiusConstant
    ) public view returns (uint256) {
        uint256 target4 = 2 *
            initializedPlanetCountByLevel[4] +
            nPlayers /
            5 +
            target4RadiusConstant;
        uint256 target5 = nPlayers / 10 + target5RadiusConstant;
        for (uint256 i = 5; i < initializedPlanetCountByLevel.length; i += 1) {
            target4 += 2 * initializedPlanetCountByLevel[i];
            target5 += 2 * initializedPlanetCountByLevel[i];
        }
        uint256 targetRadiusSquared4 = (target4 * cumulativeRarities[4] * 100) /
            314;
        uint256 targetRadiusSquared5 = (target5 * cumulativeRarities[5] * 100) /
            314;
        uint256 r4 = ABDKMath64x64.toUInt(
            ABDKMath64x64.sqrt(ABDKMath64x64.fromUInt(targetRadiusSquared4))
        );
        uint256 r5 = ABDKMath64x64.toUInt(
            ABDKMath64x64.sqrt(ABDKMath64x64.fromUInt(targetRadiusSquared5))
        );
        if (r4 > r5) {
            return r4;
        } else {
            return r5;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

library DarkForestTypes {
    enum PlanetResource {NONE, SILVER}
    enum PlanetEventType {ARRIVAL}
    enum PlanetType {PLANET, TRADING_POST}

    struct Planet {
        address owner;
        uint256 range;
        uint256 population;
        uint256 populationCap;
        uint256 populationGrowth;
        PlanetResource planetResource;
        uint256 silverCap;
        uint256 silverGrowth;
        uint256 silver;
        uint256 silverMax;
        uint256 planetLevel;
        PlanetType planetType;
    }

    struct PlanetExtendedInfo {
        bool isInitialized;
        uint256 version;
        uint256 lastUpdated;
        uint256 upgradeState0;
        uint256 upgradeState1;
        uint256 upgradeState2;
    }

    struct PlanetEventMetadata {
        uint256 id;
        PlanetEventType eventType;
        uint256 timeTrigger;
        uint256 timeAdded;
    }

    struct ArrivalData {
        uint256 id;
        address player;
        uint256 fromPlanet;
        uint256 toPlanet;
        uint256 popArriving;
        uint256 silverMoved;
        uint256 departureTime;
        uint256 arrivalTime;
    }

    struct PlanetDefaultStats {
        string label;
        uint256 populationCap;
        uint256 populationGrowth;
        uint256 range;
        uint256 silverGrowth;
        uint256 silverCap;
        uint256 silverMax;
        uint256 barbarianPercentage;
        uint256 energyCost;
    }

    struct Upgrade {
        uint256 popCapMultiplier;
        uint256 popGroMultiplier;
        uint256 silverCapMultiplier;
        uint256 silverGroMultiplier;
        uint256 silverMaxMultiplier;
        uint256 rangeMultiplier;
        uint256 silverCostMultiplier;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

// Import base Initializable contract
import "./DarkForestTypes.sol";
import "./Whitelist.sol";

contract DarkForestStorageV1 {
    // Contract housekeeping
    address public adminAddress;
    Whitelist whitelist;
    bool public paused;

    // Game config
    uint256 public VERSION;
    bool public DISABLE_ZK_CHECK;
    uint256 public constant PERLIN_THRESHOLD = 18;
    uint256 public constant GLOBAL_SPEED_IN_HUNDRETHS = 75;
    uint256 public constant PLANET_RARITY = 16384;
    uint256 public constant ENERGY_PER_SECOND = 17;
    uint256 public constant ENERGY_CAP = 200000;
    uint256 public constant TRADING_POST_RARITY = 16;
    uint256 public constant SILVER_RARITY = 4;
    uint256 public constant TRADING_POST_BARBARIANS = 50;

    // Default planet type stats
    uint256[] public planetLevelThresholds;
    uint256[] public planetTypeThresholds;
    uint256[] public cumulativeRarities;
    uint256[] public initializedPlanetCountByLevel;
    DarkForestTypes.PlanetDefaultStats[] public planetDefaultStats;
    DarkForestTypes.Upgrade[4][3] public upgrades;

    // Game world state
    uint256 gameEndTimestamp;
    uint256 target4RadiusConstant;
    uint256 target5RadiusConstant;
    uint256[] public planetIds;
    address[] public playerIds;
    uint256 public worldRadius;
    uint256 public planetEventsCount;
    mapping(uint256 => DarkForestTypes.Planet) public planets;
    mapping(uint256 => DarkForestTypes.PlanetExtendedInfo)
        public planetsExtendedInfo;
    mapping(address => bool) public isPlayerInitialized;

    // maps location id to planet events array
    mapping(uint256 => DarkForestTypes.PlanetEventMetadata[])
        public planetEvents;

    // maps event id to arrival data
    mapping(uint256 => DarkForestTypes.ArrivalData) public planetArrivals;

    // no-op for now since no player energy
    // mapping(address => DarkForestTypes.PlayerInfo) public playerInfos;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./DarkForestTypes.sol";
import "./DarkForestLazyUpdate.sol";

library DarkForestPlanet {
    function isPopCapBoost(uint256 _location) public pure returns (bool) {
        bytes memory _b = abi.encodePacked(_location);
        return uint256(uint8(_b[11])) < 16;
    }

    function isPopGroBoost(uint256 _location) public pure returns (bool) {
        bytes memory _b = abi.encodePacked(_location);
        return uint256(uint8(_b[12])) < 16;
    }

    function isResCapBoost(uint256 _location) public pure returns (bool) {
        bytes memory _b = abi.encodePacked(_location);
        return uint256(uint8(_b[13])) < 16;
    }

    function isResGroBoost(uint256 _location) public pure returns (bool) {
        bytes memory _b = abi.encodePacked(_location);
        return uint256(uint8(_b[14])) < 16;
    }

    function isRangeBoost(uint256 _location) public pure returns (bool) {
        bytes memory _b = abi.encodePacked(_location);
        return uint256(uint8(_b[15])) < 16;
    }

    function _getDecayedPop(
        uint256 _popMoved,
        uint256 _maxDist,
        uint256 _range,
        uint256 _populationCap
    ) public pure returns (uint256 _decayedPop) {
        int128 _scaleInv = ABDKMath64x64.exp_2(
            ABDKMath64x64.divu(_maxDist, _range)
        );
        int128 _bigPlanetDebuff = ABDKMath64x64.divu(_populationCap, 20);
        int128 _beforeDebuff = ABDKMath64x64.div(
            ABDKMath64x64.fromUInt(_popMoved),
            _scaleInv
        );
        if (_beforeDebuff > _bigPlanetDebuff) {
            _decayedPop = ABDKMath64x64.toUInt(
                ABDKMath64x64.sub(_beforeDebuff, _bigPlanetDebuff)
            );
        } else {
            _decayedPop = 0;
        }
    }

    function _createArrival(
        uint256 _oldLoc,
        uint256 _newLoc,
        uint256 _maxDist,
        uint256 _popMoved,
        uint256 _silverMoved,
        uint256 GLOBAL_SPEED_IN_HUNDRETHS,
        uint256 planetEventsCount,
        mapping(uint256 => DarkForestTypes.Planet) storage planets,
        mapping(uint256 => DarkForestTypes.ArrivalData) storage planetArrivals
    ) internal {
        // enter the arrival data for event id planetEventsCount
        DarkForestTypes.Planet memory planet = planets[_oldLoc];
        uint256 _popArriving = _getDecayedPop(
            _popMoved,
            _maxDist,
            planet.range,
            planet.populationCap
        );
        require(_popArriving > 0, "Not enough forces to make move");
        planetArrivals[planetEventsCount] = DarkForestTypes.ArrivalData({
            id: planetEventsCount,
            player: msg.sender,
            fromPlanet: _oldLoc,
            toPlanet: _newLoc,
            popArriving: _popArriving,
            silverMoved: _silverMoved,
            departureTime: block.timestamp,
            arrivalTime: block.timestamp +
                (_maxDist * 100) /
                GLOBAL_SPEED_IN_HUNDRETHS
        });
    }

    function initializePlanet(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.PlanetExtendedInfo storage _planetExtendedInfo,
        DarkForestTypes.PlanetDefaultStats storage _planetDefaultStats,
        uint256 _version,
        DarkForestTypes.PlanetType _planetType,
        DarkForestTypes.PlanetResource _planetResource,
        uint256 _planetLevel,
        uint256 _location
    ) public {
        _planetExtendedInfo.isInitialized = true;
        // planet initialize should set the planet to default state, including having the owner be adress 0x0
        // then it's the responsibility for the mechanics to set the owner to the player
        _planet.owner = address(0);
        _planet.range = isRangeBoost(_location)
            ? _planetDefaultStats.range * 2
            : _planetDefaultStats.range;

        _planet.populationCap = isPopCapBoost(_location)
            ? _planetDefaultStats.populationCap * 2
            : _planetDefaultStats.populationCap;

        _planet.population = _planetType ==
            DarkForestTypes.PlanetType.TRADING_POST
            ? 1500000
            : SafeMath.div(
                SafeMath.mul(
                    _planet.populationCap,
                    _planetDefaultStats.barbarianPercentage
                ),
                100
            );

        _planet.populationGrowth = isPopGroBoost(_location)
            ? _planetDefaultStats.populationGrowth * 2
            : _planetDefaultStats.populationGrowth;
        // TESTING
        // _planet.populationGrowth *= 100;

        _planet.planetResource = _planetResource;

        _planet.silverCap = isResCapBoost(_location)
            ? _planetDefaultStats.silverCap * 2
            : _planetDefaultStats.silverCap;
        _planet.silverGrowth = 0;
        if (_planetResource == DarkForestTypes.PlanetResource.SILVER) {
            _planet.silverGrowth = isResGroBoost(_location)
                ? _planetDefaultStats.silverGrowth * 2
                : _planetDefaultStats.silverGrowth;
            // TESTING
            // _planet.silverGrowth *= 100;
        }

        _planet.silver = 0;
        _planet.silverMax = _planetDefaultStats.silverMax;
        _planet.planetLevel = _planetLevel;

        _planetExtendedInfo.version = _version;
        _planetExtendedInfo.lastUpdated = block.timestamp;
        _planetExtendedInfo.upgradeState0 = 0;
        _planetExtendedInfo.upgradeState1 = 0;
        _planetExtendedInfo.upgradeState2 = 0;
    }

    function upgradePlanet(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.PlanetExtendedInfo storage _planetExtendedInfo,
        uint256 _branch,
        DarkForestTypes.PlanetDefaultStats[] storage planetDefaultStats,
        DarkForestTypes.Upgrade[4][3] storage upgrades
    ) public {
        // do checks
        require(
            _planet.owner == msg.sender,
            "Only owner can perform operation on planets"
        );
        uint256 planetLevel = _planet.planetLevel;
        require(
            planetLevel > 0,
            "Planet level is not high enough for this upgrade"
        );
        require(_branch < 3, "Upgrade branch not valid");
        uint256 upgradeBranchCurrentLevel;
        if (_branch == 0) {
            upgradeBranchCurrentLevel = _planetExtendedInfo.upgradeState0;
        } else if (_branch == 1) {
            upgradeBranchCurrentLevel = _planetExtendedInfo.upgradeState1;
        } else if (_branch == 2) {
            upgradeBranchCurrentLevel = _planetExtendedInfo.upgradeState2;
        }
        require(upgradeBranchCurrentLevel < 4, "Upgrade branch already maxed");
        if (upgradeBranchCurrentLevel == 2) {
            if (_branch == 0) {
                require(
                    _planetExtendedInfo.upgradeState1 < 3 &&
                        _planetExtendedInfo.upgradeState2 < 3,
                    "Can't upgrade a second branch to level 3"
                );
            }
            if (_branch == 1) {
                require(
                    _planetExtendedInfo.upgradeState0 < 3 &&
                        _planetExtendedInfo.upgradeState2 < 3,
                    "Can't upgrade a second branch to level 3"
                );
            }
            if (_branch == 2) {
                require(
                    _planetExtendedInfo.upgradeState0 < 3 &&
                        _planetExtendedInfo.upgradeState1 < 3,
                    "Can't upgrade a second branch to level 3"
                );
            }
        }


            DarkForestTypes.Upgrade memory upgrade
         = upgrades[_branch][upgradeBranchCurrentLevel];
        uint256 upgradeCost = (planetDefaultStats[planetLevel].silverCap *
            upgrade.silverCostMultiplier) / 100;
        require(
            _planet.silver >= upgradeCost,
            "Insufficient silver to upgrade"
        );

        // do upgrade
        _planet.populationCap =
            (_planet.populationCap * upgrade.popCapMultiplier) /
            100;
        _planet.populationGrowth =
            (_planet.populationGrowth * upgrade.popGroMultiplier) /
            100;
        _planet.silverCap =
            (_planet.silverCap * upgrade.silverCapMultiplier) /
            100;
        _planet.silverGrowth =
            (_planet.silverGrowth * upgrade.silverGroMultiplier) /
            100;
        _planet.silverMax =
            (_planet.silverMax * upgrade.silverMaxMultiplier) /
            100;
        _planet.range = (_planet.range * upgrade.rangeMultiplier) / 100;
        _planet.silver -= upgradeCost;
        if (_branch == 0) {
            _planetExtendedInfo.upgradeState0 += 1;
        } else if (_branch == 1) {
            _planetExtendedInfo.upgradeState1 += 1;
        } else if (_branch == 2) {
            _planetExtendedInfo.upgradeState2 += 1;
        }
    }

    function move(
        uint256 _oldLoc,
        uint256 _newLoc,
        uint256 _maxDist,
        uint256 _popMoved,
        uint256 _silverMoved,
        uint256 GLOBAL_SPEED_IN_HUNDRETHS,
        uint256 planetEventsCount,
        mapping(uint256 => DarkForestTypes.Planet) storage planets,
        mapping(uint256 => DarkForestTypes.PlanetEventMetadata[])
            storage planetEvents,
        mapping(uint256 => DarkForestTypes.ArrivalData) storage planetArrivals
    ) public {
        require(
            planets[_oldLoc].owner == msg.sender,
            "Only owner can perform operation on planets"
        );
        // we want strict > so that the population can't go to 0
        require(
            planets[_oldLoc].population > _popMoved,
            "Tried to move more population that what exists"
        );
        require(
            planets[_oldLoc].silver >= _silverMoved,
            "Tried to move more silver than what exists"
        );

        // all checks pass. execute move
        // push the new move into the planetEvents array for _newLoc
        planetEvents[_newLoc].push(
            DarkForestTypes.PlanetEventMetadata({
                id: planetEventsCount,
                eventType: DarkForestTypes.PlanetEventType.ARRIVAL,
                timeTrigger: block.timestamp +
                    (_maxDist * 100) /
                    GLOBAL_SPEED_IN_HUNDRETHS,
                timeAdded: block.timestamp
            })
        );

        _createArrival(
            _oldLoc,
            _newLoc,
            _maxDist,
            _popMoved,
            _silverMoved,
            GLOBAL_SPEED_IN_HUNDRETHS,
            planetEventsCount,
            planets,
            planetArrivals
        );

        // subtract ships and silver sent
        planets[_oldLoc].population -= _popMoved;
        planets[_oldLoc].silver -= _silverMoved;
    }
}

pragma solidity ^0.6.9;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "./ABDKMath64x64.sol";
import "./DarkForestTypes.sol";

library DarkForestLazyUpdate {
    function _updateSilver(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.PlanetExtendedInfo storage _planetExtendedInfo,
        uint256 _updateToTime
    ) private {
        // This function should never be called directly and should only be called
        // by the refresh planet function. This require is in place to make sure
        // no one tries to updateSilver on non silver producing planet.
        require(
            _planet.planetResource == DarkForestTypes.PlanetResource.SILVER,
            "Can only update silver on silver producing planet"
        );
        if (_planet.owner == address(0)) {
            // unowned planet doesn't gain silver
            return;
        }

        // WE NEED TO MAKE SURE WE NEVER TAKE LOG(0)
        uint256 _startSilverProd;

        if (_planet.population > _planet.populationCap / 2) {
            // midpoint was before lastUpdated, so start prod from lastUpdated
            _startSilverProd = _planetExtendedInfo.lastUpdated;
        } else {
            // midpoint was after lastUpdated, so calculate & start prod from lastUpdated
            int128 _popCap = ABDKMath64x64.fromUInt(_planet.populationCap);
            int128 _pop = ABDKMath64x64.fromUInt(_planet.population);
            int128 _logVal = ABDKMath64x64.ln(
                ABDKMath64x64.div(ABDKMath64x64.sub(_popCap, _pop), _pop)
            );

            int128 _diffNumerator = ABDKMath64x64.mul(_logVal, _popCap);
            int128 _diffDenominator = ABDKMath64x64.mul(
                ABDKMath64x64.fromUInt(4),
                ABDKMath64x64.fromUInt(_planet.populationGrowth)
            );

            int128 _popCurveMidpoint = ABDKMath64x64.add(
                ABDKMath64x64.div(_diffNumerator, _diffDenominator),
                ABDKMath64x64.fromUInt(_planetExtendedInfo.lastUpdated)
            );

            _startSilverProd = ABDKMath64x64.toUInt(_popCurveMidpoint);
        }

        // Check if the pop curve midpoint happens in the past
        if (_startSilverProd < _updateToTime) {
            uint256 _timeDiff;

            if (_startSilverProd > _planetExtendedInfo.lastUpdated) {
                _timeDiff = SafeMath.sub(_updateToTime, _startSilverProd);
            } else {
                _timeDiff = SafeMath.sub(
                    _updateToTime,
                    _planetExtendedInfo.lastUpdated
                );
            }

            if (_planet.silver < _planet.silverCap) {
                uint256 _silverMined = SafeMath.mul(
                    _planet.silverGrowth,
                    _timeDiff
                );

                _planet.silver = Math.min(
                    _planet.silverCap,
                    SafeMath.add(_planet.silver, _silverMined)
                );
            }
        }
    }

    function _updatePopulation(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.PlanetExtendedInfo storage _planetExtendedInfo,
        uint256 _updateToTime
    ) private {
        if (_planet.owner == address(0)) {
            // unowned planet doesn't increase in population
            return;
        }

        int128 _timeElapsed = ABDKMath64x64.sub(
            ABDKMath64x64.fromUInt(_updateToTime),
            ABDKMath64x64.fromUInt(_planetExtendedInfo.lastUpdated)
        );

        int128 _one = ABDKMath64x64.fromUInt(1);

        int128 _denominator = ABDKMath64x64.add(
            ABDKMath64x64.mul(
                ABDKMath64x64.exp(
                    ABDKMath64x64.div(
                        ABDKMath64x64.mul(
                            ABDKMath64x64.mul(
                                ABDKMath64x64.fromInt(-4),
                                ABDKMath64x64.fromUInt(_planet.populationGrowth)
                            ),
                            _timeElapsed
                        ),
                        ABDKMath64x64.fromUInt(_planet.populationCap)
                    )
                ),
                ABDKMath64x64.sub(
                    ABDKMath64x64.div(
                        ABDKMath64x64.fromUInt(_planet.populationCap),
                        ABDKMath64x64.fromUInt(_planet.population)
                    ),
                    _one
                )
            ),
            _one
        );

        _planet.population = ABDKMath64x64.toUInt(
            ABDKMath64x64.div(
                ABDKMath64x64.fromUInt(_planet.populationCap),
                _denominator
            )
        );
    }

    function updatePlanet(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.PlanetExtendedInfo storage _planetExtendedInfo,
        uint256 _updateToTime
    ) public {
        // assumes planet is already initialized
        _updatePopulation(_planet, _planetExtendedInfo, _updateToTime);

        if (_planet.planetResource == DarkForestTypes.PlanetResource.SILVER) {
            _updateSilver(_planet, _planetExtendedInfo, _updateToTime);
        }

        _planetExtendedInfo.lastUpdated = _updateToTime;
    }

    // assumes that the planet last updated time is equal to the arrival time trigger
    function applyArrival(
        DarkForestTypes.Planet storage _planet,
        DarkForestTypes.ArrivalData storage _planetArrival
    ) private {
        // for readability, trust me.

        // checks whether the planet is owned by the player sending ships
        if (_planetArrival.player == _planet.owner) {
            // simply increase the population if so
            _planet.population = SafeMath.add(
                _planet.population,
                _planetArrival.popArriving
            );
        } else {
            if (_planet.population > _planetArrival.popArriving) {
                // handles if the planet population is bigger than the arriving ships
                // simply reduce the amount of planet population by the arriving ships
                _planet.population = SafeMath.sub(
                    _planet.population,
                    _planetArrival.popArriving
                );
            } else {
                // handles if the planet population is equal or less the arriving ships
                // reduce the arriving ships amount with the current population and the
                // result is the new population of the planet now owned by the attacking
                // player
                _planet.owner = _planetArrival.player;
                _planet.population = SafeMath.sub(
                    _planetArrival.popArriving,
                    _planet.population
                );
                if (_planet.population == 0) {
                    // make sure pop is never 0
                    _planet.population = 1;
                }
            }
        }

        _planet.silver = Math.min(
            _planet.silverMax,
            SafeMath.add(_planet.silver, _planetArrival.silverMoved)
        );
    }

    function _applyPendingEvents(
        uint256 _location,
        mapping(uint256 => DarkForestTypes.PlanetEventMetadata[]) storage planetEvents,
        mapping(uint256 => DarkForestTypes.Planet) storage planets,
        mapping(uint256 => DarkForestTypes.PlanetExtendedInfo) storage planetsExtendedInfo,
        mapping(uint256 => DarkForestTypes.ArrivalData) storage planetArrivals
    ) public {
        uint256 _earliestEventTime;
        uint256 _bestIndex;
        do {
            // set to to the upperbound of uint256
            _earliestEventTime = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

            // loops through the array and fine the earliest event times
            for (uint256 i = 0; i < planetEvents[_location].length; i++) {
                if (
                    planetEvents[_location][i].timeTrigger < _earliestEventTime
                ) {
                    _earliestEventTime = planetEvents[_location][i].timeTrigger;
                    _bestIndex = i;
                }
            }

            // TODO: the invalid opcode error is somewhere in this block
            // only process the event if it occurs before the current time and the timeTrigger is not 0
            // which comes from uninitialized PlanetEventMetadata
            if (
                planetEvents[_location].length != 0 &&
                planetEvents[_location][_bestIndex].timeTrigger <=
                block.timestamp
            ) {
                updatePlanet(
                    planets[_location],
                    planetsExtendedInfo[_location],
                    planetEvents[_location][_bestIndex].timeTrigger
                );

                // process event based on event type
                if (
                    planetEvents[_location][_bestIndex].eventType ==
                    DarkForestTypes.PlanetEventType.ARRIVAL
                ) {
                    applyArrival(
                        planets[planetArrivals[planetEvents[_location][_bestIndex]
                            .id]
                            .toPlanet],
                        planetArrivals[planetEvents[_location][_bestIndex].id]
                    );
                }

                // swaps the array element with the one in the end, and pop it
                planetEvents[_location][_bestIndex] = planetEvents[_location][planetEvents[_location]
                    .length - 1];
                planetEvents[_location].pop();
            }
        } while (_earliestEventTime <= block.timestamp);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

// Libraries
import "./ABDKMath64x64.sol";
import "./DarkForestTypes.sol";

library DarkForestInitialize {
    function initializeDefaults(
        DarkForestTypes.PlanetDefaultStats[] storage planetDefaultStats
    ) public {
        planetDefaultStats.push(
            DarkForestTypes.PlanetDefaultStats({
                label: "Asteroid",
                populationCap: 150000,
                populationGrowth: 750,
                range: 99,
                silverGrowth: 0,
                silverCap: 0,
                silverMax: 0,
                barbarianPercentage: 0,
                energyCost: 0
            })
        );

        planetDefaultStats.push(
            DarkForestTypes.PlanetDefaultStats({
                label: "Brown Dwarf",
                populationCap: 500000,
                populationGrowth: 1000,
                range: 177,
                silverGrowth: 28,
                silverCap: 20000,
                silverMax: 40000,
                barbarianPercentage: 0,
                energyCost: 5
            })
        );

        planetDefaultStats.push(
            DarkForestTypes.PlanetDefaultStats({
                label: "Red Dwarf",
                populationCap: 1500000,
                populationGrowth: 1250,
                range: 315,
                silverGrowth: 139,
                silverCap: 250000,
                silverMax: 500000,
                barbarianPercentage: 2,
                energyCost: 10
            })
        );

        planetDefaultStats.push(
            DarkForestTypes.PlanetDefaultStats({
                label: "White Dwarf",
                populationCap: 5000000,
                populationGrowth: 1500,
                range: 591,
                silverGrowth: 889,
                silverCap: 3200000,
                silverMax: 6400000,
                barbarianPercentage: 3,
                energyCost: 15
            })
        );

        planetDefaultStats.push(
            DarkForestTypes.PlanetDefaultStats({
                label: "Yellow Star",
                populationCap: 15000000,
                populationGrowth: 1750,
                range: 1025,
                silverGrowth: 3556,
                silverCap: 32000000,
                silverMax: 64000000,
                barbarianPercentage: 4,
                energyCost: 20
            })
        );

        planetDefaultStats.push(
            DarkForestTypes.PlanetDefaultStats({
                label: "Blue Star",
                populationCap: 40000000,
                populationGrowth: 2000,
                range: 1261,
                silverGrowth: 5333,
                silverCap: 134400000,
                silverMax: 268800000,
                barbarianPercentage: 5,
                energyCost: 25
            })
        );

        planetDefaultStats.push(
            DarkForestTypes.PlanetDefaultStats({
                label: "Giant",
                populationCap: 60000000,
                populationGrowth: 2250,
                range: 1577,
                silverGrowth: 6667,
                silverCap: 240000000,
                silverMax: 480000000,
                barbarianPercentage: 9,
                energyCost: 30
            })
        );

        planetDefaultStats.push(
            DarkForestTypes.PlanetDefaultStats({
                label: "Supergiant",
                populationCap: 75000000,
                populationGrowth: 2500,
                range: 1892,
                silverGrowth: 6667,
                silverCap: 288000000,
                silverMax: 576000000,
                barbarianPercentage: 10,
                energyCost: 35
            })
        );
    }

    function initializeUpgrades(DarkForestTypes.Upgrade[4][3] storage upgrades)
        public
    {
        upgrades[0][0] = DarkForestTypes.Upgrade({
            popCapMultiplier: 100,
            popGroMultiplier: 100,
            silverCapMultiplier: 110,
            silverGroMultiplier: 110,
            silverMaxMultiplier: 110,
            rangeMultiplier: 100,
            silverCostMultiplier: 25
        });
        upgrades[0][1] = DarkForestTypes.Upgrade({
            popCapMultiplier: 100,
            popGroMultiplier: 100,
            silverCapMultiplier: 115,
            silverGroMultiplier: 115,
            silverMaxMultiplier: 115,
            rangeMultiplier: 100,
            silverCostMultiplier: 60
        });
        upgrades[0][2] = DarkForestTypes.Upgrade({
            popCapMultiplier: 100,
            popGroMultiplier: 100,
            silverCapMultiplier: 135,
            silverGroMultiplier: 135,
            silverMaxMultiplier: 135,
            rangeMultiplier: 85,
            silverCostMultiplier: 120
        });
        upgrades[0][3] = DarkForestTypes.Upgrade({
            popCapMultiplier: 100,
            popGroMultiplier: 100,
            silverCapMultiplier: 160,
            silverGroMultiplier: 160,
            silverMaxMultiplier: 160,
            rangeMultiplier: 80,
            silverCostMultiplier: 240
        });

        upgrades[1][0] = DarkForestTypes.Upgrade({
            popCapMultiplier: 110,
            popGroMultiplier: 110,
            silverCapMultiplier: 100,
            silverGroMultiplier: 100,
            silverMaxMultiplier: 100,
            rangeMultiplier: 100,
            silverCostMultiplier: 25
        });
        upgrades[1][1] = DarkForestTypes.Upgrade({
            popCapMultiplier: 115,
            popGroMultiplier: 115,
            silverCapMultiplier: 100,
            silverGroMultiplier: 100,
            silverMaxMultiplier: 100,
            rangeMultiplier: 100,
            silverCostMultiplier: 50
        });
        upgrades[1][2] = DarkForestTypes.Upgrade({
            popCapMultiplier: 135,
            popGroMultiplier: 135,
            silverCapMultiplier: 100,
            silverGroMultiplier: 100,
            silverMaxMultiplier: 100,
            rangeMultiplier: 85,
            silverCostMultiplier: 90
        });
        upgrades[1][3] = DarkForestTypes.Upgrade({
            popCapMultiplier: 160,
            popGroMultiplier: 160,
            silverCapMultiplier: 100,
            silverGroMultiplier: 100,
            silverMaxMultiplier: 100,
            rangeMultiplier: 80,
            silverCostMultiplier: 170
        });

        upgrades[2][0] = DarkForestTypes.Upgrade({
            popCapMultiplier: 100,
            popGroMultiplier: 100,
            silverCapMultiplier: 100,
            silverGroMultiplier: 100,
            silverMaxMultiplier: 100,
            rangeMultiplier: 110,
            silverCostMultiplier: 25
        });
        upgrades[2][1] = DarkForestTypes.Upgrade({
            popCapMultiplier: 100,
            popGroMultiplier: 100,
            silverCapMultiplier: 100,
            silverGroMultiplier: 100,
            silverMaxMultiplier: 100,
            rangeMultiplier: 115,
            silverCostMultiplier: 50
        });
        upgrades[2][2] = DarkForestTypes.Upgrade({
            popCapMultiplier: 80,
            popGroMultiplier: 80,
            silverCapMultiplier: 100,
            silverGroMultiplier: 100,
            silverMaxMultiplier: 100,
            rangeMultiplier: 125,
            silverCostMultiplier: 90
        });
        upgrades[2][3] = DarkForestTypes.Upgrade({
            popCapMultiplier: 75,
            popGroMultiplier: 75,
            silverCapMultiplier: 100,
            silverGroMultiplier: 100,
            silverMaxMultiplier: 100,
            rangeMultiplier: 135,
            silverCostMultiplier: 170
        });
    }
}

// SPDX-License-Identifier: UNLICENSED
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m), uint256 (x) + uint256 (y) >> 1));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64, 0x10000000000000000));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << 127 - msb;
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= 63 - (x >> 64);
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= xe;
      else x <<= -xe;

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= re;
      else if (re < 0) result >>= -re;

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x, uint256 r) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      require (r > 0);
      while (true) {
        uint256 rr = x / r;
        if (r == rr || r + 1 == rr) return uint128 (r);
        else if (r == rr + 1) return uint128 (rr);
        r = r + rr + 1 >> 1;
      }
    }
  }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}