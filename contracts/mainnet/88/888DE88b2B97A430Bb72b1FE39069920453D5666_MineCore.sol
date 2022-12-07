// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

// Import base Initializable contract
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "./Verifier.sol";
import "./MineStorage.sol";
import "./MineUtils.sol";
import "./Mine.sol";
import "./MineInitialize.sol";
import "./ReentrancyGuarded.sol";
import "./IDarwin1155.sol";

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


contract MineCore is MineStorage {
    using ABDKMath64x64 for *;
    using SafeMath for *;
    using Math for uint256;

    event PlayerInitialized(address indexed player, uint256 indexed curRound, uint256 indexed loc);
    event ArrivalQueued(uint256 arrivalId);

    function initialize(
        bool _disableZKCheck
    ) public initializer {
        paused = false;

        VERSION = 1;
        DISABLE_ZK_CHECK = _disableZKCheck;

        mineTypeThresholds = [65536, 0];

        mineLevelThresholds = [
            16777216,
            4194256,
            1048516,
            262081,
            65472,
            16320,
            4032,
            960
        ];

        MineInitialize.initializeDefaults(mineDefaultStats);
        
        for (uint256 i = 0; i < mineLevelThresholds.length; i += 1) {
            cumulativeRarities.push(
                (2**24 / mineLevelThresholds[i]) * PLANET_RARITY
            );
        }

        worldRadius =30000;
    }


    modifier notPaused() {
        require(!paused, "Game is paused");
        _;
    }

    /////////////////////////////
    /// Administrative Engine ///
    /////////////////////////////


    function pause() public onlyOwner {
        require(!paused, "Game is already paused");
        paused = true;
    }

    function unpause() public onlyOwner {
        require(paused, "Game is already unpaused");
        paused = false;
    }

    function setDarwin1155Contract(address addr) public onlyOwner{
        _darwin1155Contract = addr;
    }   


    //////////////
    /// Helper ///
    //////////////

    function currentRound() public view returns (uint256) {
        return MineUtils._currentRound();
    }

    function LOCATION_ID_UB() public view returns (uint256) {
        return MineUtils._LOCATION_ID_UB();
    }

    function getMineLevelThresholds() public view returns (uint256[] memory) {
        return mineLevelThresholds;
    }

    function getMineTypeThresholds() public view returns (uint256[] memory) {
        return mineTypeThresholds;
    }

    function getMineCumulativeRarities()
        public
        view
        returns (uint256[] memory)
    {
        return cumulativeRarities;
    }

    function getDefaultStats()
        public
        view
        returns (MineTypes.MineDefaultStats[] memory)
    {

        MineTypes.MineDefaultStats[] memory ret
         = new MineTypes.MineDefaultStats[](
            mineLevelThresholds.length
        );
        for (uint256 i = 0; i < mineLevelThresholds.length; i += 1) {
            ret[i] = mineDefaultStats[i];
        }
        return ret;
    }

    function locationIdValid(uint256 _loc) public view returns (bool) {
        //should i check loc(x,y) out of world radius

        if(DISABLE_ZK_CHECK) { return true; }
        
        return (_loc < (LOCATION_ID_UB() / PLANET_RARITY));
    }

    

    // private utilities    
    function _mine(uint256 loc) internal view returns (MineTypes.Mine storage) {
        return mines[MineUtils._currentRound()][loc];
    }

    function _playerInfo(address addr) internal view returns (PlayerInfo storage) {
        return _playerInfoMap()[addr];
    }

    
    function _mineArrivalArr(uint256 loc) internal view returns (MineTypes.ArrivalData[] storage){
        return mineArrivalsMap[MineUtils._currentRound()][loc];
    }


    function _playerInfoMap() internal view returns (mapping(address=>PlayerInfo) storage){
        return playerInfoMap[MineUtils._currentRound()];
    }

    function _darwin1155() internal view returns (IDarwin1155) {
        return IDarwin1155(_darwin1155Contract);
    }


    function _initializeMine(uint256 _location) private {
        require(locationIdValid(_location), "Not a valid planet location");

        uint256 _level = MineUtils._getMineLevel(_location, mineLevelThresholds);

        Mine.initializeMine(
            _mine(_location),
            mineDefaultStats[_level],
            _level,
            _location
        );
    }

    //////////////////////
    /// Game Mechanics ///
    //////////////////////

    function _applyPendingEvents(
        MineTypes.Mine storage mine, 
        MineTypes.ArrivalData[] storage mineArrivals,
        mapping(address=>PlayerInfo) storage playerInfos
    ) internal {
        uint256 _earliestEventTime;
        uint256 _bestIndex;
        do {
            // set to to the upperbound of uint256
            _earliestEventTime = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
            // loops through the array and fine the earliest event times
            for (uint256 i = 0; i < mineArrivals.length; i++) {
                if (mineArrivals[i].arrivalTime < _earliestEventTime) {
                    _earliestEventTime = mineArrivals[i].arrivalTime;
                    _bestIndex = i;
                }
            }
            
            // process the arrived move event
            if (mineArrivals.length != 0 && 
                    mineArrivals[_bestIndex].arrivalTime <=block.timestamp) {
                //if the mine owner is adrres(0), occupy it 
                if(mine.owner == address(0)){   
                    mine.owner = mineArrivals[_bestIndex].player;
                }
                //update player location
                playerInfos[mine.owner].location = mine.location;
                playerInfos[mine.owner].move = false;
            }

            // swaps the array element with the one in the end, and pop it
            mineArrivals[_bestIndex] = mineArrivals[mineArrivals.length - 1];
            mineArrivals.pop();
        } while (_earliestEventTime <= block.timestamp);
    }

    function refreshMine(uint256 _location)
        public
        notPaused reentrancyGuard
    {
        // apply all pending events until the current timestamp
        _applyPendingEvents(
            _mine(_location),
            _mineArrivalArr(_location),
            _playerInfoMap()
        );
    }
    

    function initializePlayer(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[3] memory _input
    ) public notPaused reentrancyGuard{
        /*
            // flows
            * init mine info
            * set mine owner to msg.sender
            * set player location
            
            //checks
            * ZK check
            * player inited check
            * mine init check
            * mine owner check
            * radius check
        */

        if (!DISABLE_ZK_CHECK) {
            require(
                Verifier.verifyInitProof(_a, _b, _c, _input),
                "Failed init proof check"
            );
        }

        uint256 _location = _input[0];
        // uint256 _perlin = _input[1];
        uint256 _radius = _input[2];

        // require(
        //     !minesExtendedInfo[MineUtils._currentRound()][_location].isInitialized,
        //     "Planet is already initialized"
        // );

        require(
            _radius <= worldRadius,
            "Init radius is bigger than the current world radius"
        );

        require(!_playerInfo(msg.sender).isInitialized, "player had inited");
        require(!_mine(_location).isInitialized, "mine had inited");
        require(_mine(_location).owner == address(0), "mine owner not empty");

        // require(
        //     _perlin <= PERLIN_THRESHOLD,
        //     "Init not allowed in perlin value above the threshold"
        // );

        // Initialize mine information
        _initializeMine(_location);

        _mine(_location).owner = msg.sender;

        _playerInfo(msg.sender).location = _location;
        _playerInfo(msg.sender).isInitialized = true;
        _playerInfo(msg.sender).move = false;

        emit PlayerInitialized(msg.sender, MineUtils._currentRound(), _location);
    }

    function move(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[7] memory _input
    ) public notPaused reentrancyGuard{
        /*
            flows :
            * claim mine
            * init or refresh mines
            * refresh old mine
            * create arrive data
            * old mine clear owner
            * player set to move
            
            checks :
            * ZK
            * oldmine.owner is msg.sender
            * player not in move
            * radius check
        */
        uint256 _oldLoc = _input[0];
        uint256 _newLoc = _input[1];
        uint256 _newPerlin = _input[2];
        uint256 _newRadius = _input[3];
        uint256 _maxDist = _input[4];
        
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

        MineTypes.Mine storage oldMine = _mine(_oldLoc);

        require(_oldLoc != _newLoc, "you can't move the same pos");
        
        require(
            oldMine.owner == msg.sender, "Only owner can perform operation on old mine"
        );

        require(!_playerInfo(msg.sender).move, "Player is moving in progress");

        require(_playerInfo(msg.sender).location != _newLoc, "you are in this position");

        // check radius
        require(_newRadius <= worldRadius, "Attempting to move out of bounds");

        claim(_oldLoc);

        MineTypes.ArrivalData[] storage arrivalArr = _mineArrivalArr(_newLoc);

        // Only perform if the toMine have never initialized previously
        if (!_mine(_newLoc).isInitialized) {
            _initializeMine(_newLoc);
        } else {
            // need to do this so people can't deny service to their own mine with gas limit
            refreshMine(_newLoc);
            require(arrivalArr.length < 8, "new mine is rate-limited");
        }

        // Refresh from mine first before doing any action on it
        refreshMine(_oldLoc);

        arrivalArr.push(
            MineTypes.ArrivalData({
            player: msg.sender,
            fromPlanet: _oldLoc,
            toPlanet: _newLoc,
            departureTime: block.timestamp,
            arrivalTime: block.timestamp +
                (_maxDist * 100) /
                GLOBAL_SPEED_IN_HUNDRETHS
        }));

        //remove old mine's owner
        oldMine.owner = address(0);

        _playerInfo(msg.sender).move = true;
        _playerInfo(msg.sender).location = _newLoc;
    }

    function _claim(uint256 _location) internal notPaused {
        /*
            flows:
            * calc all mine out
            * mark last claim
            * send nfts out

            check:
            * mine owner check
            * time check
            * mine end time check
        */
        MineTypes.Mine storage mine = _mine(_location);

        address beneficiary = mine.owner;

        require(beneficiary != address(0), "_location must have owner");

        require(block.timestamp > mine.lastClaim, "time elapse too small");
        require(mine.endTime >= mine.lastClaim, "mine time check error");

        
        uint256 timeElapsed = SafeMath.sub(block.timestamp, mine.lastClaim);
        uint256 timeLeft    = SafeMath.sub(mine.endTime, mine.lastClaim);

        //if timeleft is zero, so if match the timeLeft <= timeElapsed, the mineRate is zero; otherwise the rate is less then 10000
        uint256 mineRate = (timeLeft <= timeElapsed) ? 10000 : SafeMath.div(timeElapsed * 10000, timeLeft);

        require(mineRate <= 10000, "internal check error");

        /*
        100304
        100303
        100305
        100306
        100045
        */
        
        uint256[] memory outIds = new uint256[](5);
        outIds[0] = 100304;
        outIds[1] = 100303;
        outIds[2] = 100305;
        outIds[3] = 100306;
        outIds[4] = 100045;
        
        uint256[] memory outAmount = new uint256[](5);
        outAmount[0] = SafeMath.div(SafeMath.mul(mine.copper,mineRate), 10000);
        outAmount[1] = SafeMath.div(SafeMath.mul(mine.iron,mineRate), 10000);
        outAmount[2] = SafeMath.div(SafeMath.mul(mine.silver,mineRate), 10000);
        outAmount[3] = SafeMath.div(SafeMath.mul(mine.gold,mineRate), 10000);
        outAmount[4] = SafeMath.div(SafeMath.mul(mine.redStone,mineRate), 10000);
        

        mine.copper    = SafeMath.sub(mine.copper, outAmount[0]);
        mine.iron      = SafeMath.sub(mine.iron, outAmount[1]);
        mine.silver    = SafeMath.sub(mine.silver, outAmount[2]);
        mine.gold      = SafeMath.sub(mine.gold, outAmount[3]);
        mine.redStone  = SafeMath.sub(mine.redStone, outAmount[4]);

        mine.lastClaim = block.timestamp;

       _darwin1155().claim(msg.sender, outIds, outAmount, "claim mine");
    }

    function claim(uint256 _location) public notPaused reentrancyGuard{
        address beneficiary = _mine(_location).owner;
        require(beneficiary == msg.sender, "_location not yours");
        _claim(_location);
    }

    function turbo(uint256 tokenId, uint256 amount) public notPaused reentrancyGuard{
        PlayerInfo memory playerInfo = _playerInfo(msg.sender);

        require(playerInfo.isInitialized, "player not inited");

        uint256 t = SafeMath.mul(MineUtils._tokenIdToSecond(tokenId), amount);

        uint256 loc = playerInfo.location;
        require(loc > 0, "player location is zero");



        //-- todo
        _darwin1155().burn(msg.sender, tokenId, amount);

        //-- burn nfts here
        if(playerInfo.move){    //turbo move
            MineTypes.ArrivalData[] storage mineArrivals = _mineArrivalArr(loc);
            for (uint256 i = 0; i < mineArrivals.length; i++) {
                if (mineArrivals[i].player == msg.sender) {
                    /*
                        uint256 departureTime;
                        uint256 arrivalTime;
                    */
                    if(t >= mineArrivals[i].arrivalTime){
                            mineArrivals[i].arrivalTime = mineArrivals[i].departureTime;
                    }else{
                            mineArrivals[i].arrivalTime = SafeMath.sub(mineArrivals[i].arrivalTime, t);
                    }
                    if(mineArrivals[i].arrivalTime < mineArrivals[i].departureTime){
                        mineArrivals[i].arrivalTime = mineArrivals[i].departureTime;
                    }
                    break;
                }
            }
            _applyPendingEvents(
                _mine(loc),
                _mineArrivalArr(loc),
                _playerInfoMap()
            );
        }else{                  //turbo mining
            /*
            uint256 lastClaim;
            uint256 endTime;
            */
            MineTypes.Mine storage mine = _mine(loc);

            require(mine.owner == msg.sender, "The mine is not yours");

            require(mine.endTime > block.timestamp, "The mine not need to boost");

            if(t > mine.endTime){
                mine.endTime = block.timestamp;
            }else {
                mine.endTime = SafeMath.sub(mine.endTime, t);
            }
            _claim(loc);              
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

import "./MineUtils.sol";

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
        uint256 snark_scalar_field = MineUtils._LOCATION_ID_UB();
        
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
contract ReentrancyGuarded {

    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;

// Libraries
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./ABDKMath64x64.sol";
import "./MineTypes.sol";

library MineUtils {
    function _calculateByteUInt(
        bytes memory _b,
        uint256 _startByte,
        uint256 _endByte
    ) public pure returns (uint256 _byteUInt) {
        for (uint256 i = _startByte; i <= _endByte; i++) {
            _byteUInt += uint256(uint8(_b[i])) * (256**(_endByte - i));
        }
    }

    function _getMineLevel(
        uint256 _location,
        uint256[] storage planetLevelThresholds
    ) public view returns (uint256) {
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
        return level;
    }

    function _getRadius() public pure returns (uint256) {
        return 30000;
    }

    function _minePeriod(uint256 _level) public pure returns(uint256){
        uint256[] memory _t = new  uint256[](8);

        _t[0]=15;
        _t[1]=30;
        _t[2]=60;
        _t[3]=120;
        _t[4]=240;
        _t[5]=480;
        _t[6]=960;
        _t[7]=1440;

        require(_level <= _t.length, "mine level error");
        return SafeMath.mul(_t[_level], 60);
    }

    function _LOCATION_ID_UB() public view returns(uint256){
        uint256[] memory LOCATION_ID_UBS = new  uint256[](
            3
        );

        LOCATION_ID_UBS[0]=21888242871839275222246405745257275088548364400416034343698204186575808495617;
        LOCATION_ID_UBS[1]=11824328918523744040220862726880617129415753719450549270591293113798951636479;
        LOCATION_ID_UBS[2]=7342815532046203103754594889379096650670623670887051067490729080372571921980;

        uint256 _round = _currentRound();

        require(_round < LOCATION_ID_UBS.length, "round not define");

        return LOCATION_ID_UBS[_round];
    }


    function _currentRound() public view returns (uint256) {
        uint256 startTime = 1663171200;

        uint256 period = 31536000;
        //uint256 period = 604800;  

        if(block.timestamp < startTime){
            return 0;
        }

        uint256 timeElapsed = block.timestamp - startTime;

        return timeElapsed / period;
    }

    function _tokenIdToSecond (uint256 tokenId) public pure returns (uint64) {
        if(tokenId == 5000){
            return 60;
        }else if(tokenId == 5001){
            return 900;
        }else if(tokenId == 5002){
            return 3600;
        }else if(tokenId == 5003){
            return 14400;
        }else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;

library MineTypes {
    enum MineEventType {ARRIVAL}

    struct Mine {
        address owner;
        uint256 copper;
        uint256 iron;
        uint256 silver;
        uint256 gold;
        uint256 redStone;
        uint256 mineLevel;
        bool    move;
        bool    isInitialized;
        uint256 lastClaim;
        uint256 endTime;
        uint256 location;
    }

    struct MineDefaultStats {
        string  label;
        uint256 copper;
        uint256 iron;
        uint256 silver;
        uint256 gold;
        uint256 redStone;
        uint256 energy;
    }


    struct ArrivalData {
        address player;
        uint256 fromPlanet;
        uint256 toPlanet;
        uint256 departureTime;
        uint256 arrivalTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;

// Import base Initializable contract
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "./MineTypes.sol";
import "./Ownable.sol";
import "./MineUtils.sol";
import "./ReentrancyGuarded.sol";

contract MineStorage is Ownable, ReentrancyGuarded,Initializable{

    struct PlayerInfo{
        uint256 location;   // Player current mine position
        bool move;          // player current in moving?
        bool isInitialized; // player is init
    }

    bool public paused;

    // Game config
    uint256 public VERSION;

    bool public DISABLE_ZK_CHECK;

    uint256 public constant PERLIN_THRESHOLD = 18;
    uint256 public constant GLOBAL_SPEED_IN_HUNDRETHS = 75;
    uint256 public constant PLANET_RARITY = 16384;
    
    
    // Default planet type stats
    uint256[] public mineLevelThresholds;
    uint256[] public mineTypeThresholds;
    uint256[] public cumulativeRarities;

    // Game world state
    uint256 public worldRadius;
    
    // Mines ( round => location=> mine)
    mapping(uint256 => mapping(uint256 => MineTypes.Mine)) public mines;

    MineTypes.MineDefaultStats[] public mineDefaultStats;

    //darwin 1155 resource contract
    address public _darwin1155Contract;
    

    //map round location move event
    //      round              location         arrival array
    mapping(uint256 => mapping(uint256 => MineTypes.ArrivalData[]))           public mineArrivalsMap;
    
    mapping(uint256=> mapping(address=>PlayerInfo)) internal playerInfoMap;

    function isPlayerInitialized(address addr) public view returns (bool) {
        return playerInfoMap[MineUtils._currentRound()][addr].location > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;

// Libraries
import "./ABDKMath64x64.sol";
import "./MineTypes.sol";

library MineInitialize {
    function initializeDefaults(
        MineTypes.MineDefaultStats[] storage mineDefaultStats
    ) public {
        mineDefaultStats.push(
            MineTypes.MineDefaultStats({
                label: "0",
                copper: 10,
                iron:0,
                silver:0,
                gold:0,
                redStone:0,
                energy:0
            })
        );
        mineDefaultStats.push(
            MineTypes.MineDefaultStats({
                label: "1",
                copper: 15,
                iron:5,
                silver:0,
                gold:0,
                redStone:0,
                energy:0
            })
        );
        mineDefaultStats.push(
            MineTypes.MineDefaultStats({
                label: "2",
                copper: 30,
                iron:0,
                silver:9,
                gold:0,
                redStone:1,
                energy:0
            })
        );
        mineDefaultStats.push(
            MineTypes.MineDefaultStats({
                label: "3",
                copper: 60,
                iron:0,
                silver:0,
                gold:18,
                redStone:2,
                energy:0
            })
        );
        mineDefaultStats.push(
            MineTypes.MineDefaultStats({
                label: "4",
                copper: 120,
                iron:36,
                silver:0,
                gold:0,
                redStone:4,
                energy:0
            })
        );
        mineDefaultStats.push(
            MineTypes.MineDefaultStats({
                label: "5",
                copper: 0,
                iron:250,
                silver:0,
                gold:62,
                redStone:8,
                energy:0
            })
        );
        mineDefaultStats.push(
            MineTypes.MineDefaultStats({
                label: "6",
                copper: 0,
                iron:440,
                silver:184,
                gold:0,
                redStone:16,
                energy:0
            })
        );
        mineDefaultStats.push(
            MineTypes.MineDefaultStats({
                label: "7",
                copper: 0,
                iron:0,
                silver:800,
                gold:128,
                redStone:32,
                energy:0
            })
        );
        
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./MineTypes.sol";
import "./MineUtils.sol";

library Mine {
    function initializeMine(
        MineTypes.Mine storage _mine,
        MineTypes.MineDefaultStats storage _mineDefaultStats,
        uint256 _mineLevel,
        uint256 _location
    ) public {
        // mine initialize should set the mine to default state, including having the owner be adress 0x0
        // then it's the responsibility for the mechanics to set the owner to the player
        require(!_mine.isInitialized, "mine is initilized");
        
        _mine.owner = address(0);
        _mine.copper = _mineDefaultStats.copper;
        _mine.iron   = _mineDefaultStats.iron;
        _mine.silver = _mineDefaultStats.silver;
        _mine.gold  = _mineDefaultStats.gold;
        _mine.redStone = _mineDefaultStats.redStone;
        _mine.mineLevel = _mineLevel;
        _mine.lastClaim = block.timestamp;
        _mine.endTime   = SafeMath.add(block.timestamp,MineUtils._minePeriod(_mineLevel));
        _mine.isInitialized = true;
        _mine.location = _location;
    }
}

/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/


// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

pragma experimental ABIEncoderV2;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IDarwin1155{
    function burn(address from, uint256 id, uint256 amount) external ;

    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external ;

    function claim(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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