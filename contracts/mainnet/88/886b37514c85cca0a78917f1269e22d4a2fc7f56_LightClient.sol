pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

import "./StepVerifier.sol";
import "./RotateVerifier.sol";
import "./libraries/SimpleSerialize.sol";
import "./interfaces/ILightClient.sol";

struct Groth16Proof {
    uint256[2] a;
    uint256[2][2] b;
    uint256[2] c;
}

struct LightClientStep {
    uint256 attestedSlot;
    uint256 finalizedSlot;
    uint256 participation;
    bytes32 finalizedHeaderRoot;
    bytes32 executionStateRoot;
    Groth16Proof proof;
}

struct LightClientRotate {
    LightClientStep step;
    bytes32 syncCommitteeSSZ;
    bytes32 syncCommitteePoseidon;
    Groth16Proof proof;
}

contract LightClient is ILightClient, StepVerifier, RotateVerifier {
    bytes32 public immutable GENESIS_VALIDATORS_ROOT;
    uint256 public immutable GENESIS_TIME;
    uint256 public immutable SECONDS_PER_SLOT;
    uint256 public immutable SLOTS_PER_EPOCH;

    uint256 internal constant OPTIMISTIC_UPDATE_TIMEOUT = 86400;
    uint256 internal constant SLOTS_PER_SYNC_COMMITTEE_PERIOD = 8192;
    uint256 internal constant MIN_SYNC_COMMITTEE_PARTICIPANTS = 10;
    uint256 internal constant SYNC_COMMITTEE_SIZE = 512;
    uint256 internal constant FINALIZED_ROOT_INDEX = 105;
    uint256 internal constant NEXT_SYNC_COMMITTEE_INDEX = 55;
    uint256 internal constant EXECUTION_STATE_ROOT_INDEX = 402;

    bool public consistent = true;
    uint256 public head = 0;
    mapping(uint256 => bytes32) public headers;
    mapping(uint256 => bytes32) public executionStateRoots;
    mapping(uint256 => bytes32) public syncCommitteePoseidons;
    mapping(uint256 => LightClientRotate) public bestUpdates;

    event HeadUpdate(uint256 indexed slot, bytes32 indexed root);
    event SyncCommitteeUpdate(uint256 indexed period, bytes32 indexed root);

    constructor(
        bytes32 genesisValidatorsRoot,
        uint256 genesisTime,
        uint256 secondsPerSlot,
        uint256 slotsPerEpoch,
        uint256 syncCommitteePeriod,
        bytes32 syncCommitteePoseidon
    ) {
        GENESIS_VALIDATORS_ROOT = genesisValidatorsRoot;
        GENESIS_TIME = genesisTime;
        SECONDS_PER_SLOT = secondsPerSlot;
        SLOTS_PER_EPOCH = slotsPerEpoch;
        setSyncCommitteePoseidon(syncCommitteePeriod, syncCommitteePoseidon);
    }

    /*
     * @dev Updates the head of the light client. The conditions for updating
     * involve checking the existence of:
     *   1) At least 2n/3+1 signatures from the current sync committee for n=512
     *   2) A valid finality proof
     *   3) A valid execution state root proof
     */
    function step(LightClientStep memory update) external {
        bool finalized = processStep(update);

        if (getCurrentSlot() < update.attestedSlot) {
            revert("Update slot is too far in the future");
        }

        if (finalized) {
            setHead(update.finalizedSlot, update.finalizedHeaderRoot);
            setExecutionStateRoot(update.finalizedSlot, update.executionStateRoot);
        }
    }

    /*
     * @dev Sets the sync committee validator set root for the next sync
     * committee period. This root is signed by the current sync committee. In
     * the case there is no finalization, we will keep track of the best
     * optimistic update.
     */
    function rotate(LightClientRotate memory update) external {
        LightClientStep memory step = update.step;
        bool finalized = processStep(update.step);
        uint256 currentPeriod = getSyncCommitteePeriod(step.finalizedSlot);
        uint256 nextPeriod = currentPeriod + 1;

        zkLightClientRotate(update);

        if (finalized) {
            setSyncCommitteePoseidon(nextPeriod, update.syncCommitteePoseidon);
        } else {
            LightClientRotate memory bestUpdate = bestUpdates[currentPeriod];
            if (step.participation < bestUpdate.step.participation) {
                revert("There exists a better update");
            }
            setBestUpdate(currentPeriod, update);
        }
    }

    /*
      * @dev In the case that there is no finalization for a sync committee
      * rotation, applies the update with the most signatures throughout the
      * period.
      */
    function force(uint256 period) external {
        LightClientRotate memory update = bestUpdates[period];
        uint256 nextPeriod = period + 1;

        if (update.step.finalizedHeaderRoot == 0) {
            revert("Best update was never initialized");
        } else if (syncCommitteePoseidons[nextPeriod] != 0) {
            revert("Sync committee for next period already initialized.");
        } else if (getSyncCommitteePeriod(getCurrentSlot()) < nextPeriod) {
            revert("Must wait for current sync committee period to end.");
        }

        setSyncCommitteePoseidon(nextPeriod, update.syncCommitteePoseidon);
    }

    function processStep(LightClientStep memory update) internal view returns (bool) {
        uint256 currentPeriod = getSyncCommitteePeriod(update.attestedSlot);

        if (syncCommitteePoseidons[currentPeriod] == 0) {
            revert("Sync committee for current period is not initialized.");
        } else if (update.participation < MIN_SYNC_COMMITTEE_PARTICIPANTS) {
            revert("Less than MIN_SYNC_COMMITTEE_PARTICIPANTS signed.");
        }

        zkLightClientStep(update);

        return 3 * update.participation > 2 * SYNC_COMMITTEE_SIZE;
    }

    function zkLightClientStep(LightClientStep memory update) internal view {
        bytes32 attestedSlotLE = SSZ.toLittleEndian(update.attestedSlot);
        bytes32 finalizedSlotLE = SSZ.toLittleEndian(update.finalizedSlot);
        bytes32 participationLE = SSZ.toLittleEndian(update.participation);
        uint256 currentPeriod = getSyncCommitteePeriod(update.attestedSlot);
        bytes32 syncCommitteePoseidon = syncCommitteePoseidons[currentPeriod];

        bytes32 h;
        h = sha256(bytes.concat(attestedSlotLE, finalizedSlotLE));
        h = sha256(bytes.concat(h, update.finalizedHeaderRoot));
        h = sha256(bytes.concat(h, participationLE));
        h = sha256(bytes.concat(h, update.executionStateRoot));
        h = sha256(bytes.concat(h, syncCommitteePoseidon));
        uint256 t = uint256(SSZ.toLittleEndian(uint256(h)));
        t = t & ((uint256(1) << 253) - 1);

        uint256[1] memory inputs = [uint256(t)];
        if (!verifyProofStep(update.proof.a, update.proof.b, update.proof.c, inputs)) {
            revert("Failed to verify step proof.");
        }
    }

    function zkLightClientRotate(LightClientRotate memory update) internal view {
        uint256[65] memory inputs;
        uint256 syncCommitteeSSZNumeric = uint256(update.syncCommitteeSSZ);
        for (uint256 i = 0; i < 32; i++) {
            inputs[32 - 1 - i] = syncCommitteeSSZNumeric % 2**8;
            syncCommitteeSSZNumeric = syncCommitteeSSZNumeric / 2**8;
        }
        inputs[32] = uint256(SSZ.toLittleEndian(uint256(update.syncCommitteePoseidon)));
        uint256 finalizedHeaderRootNumeric = uint256(update.step.finalizedHeaderRoot);
        for (uint256 i = 0; i < 32; i++) {
            inputs[65 - 1 - i] = finalizedHeaderRootNumeric % 2**8;
            finalizedHeaderRootNumeric = finalizedHeaderRootNumeric / 2**8;
        }

        if (!verifyProofRotate(update.proof.a, update.proof.b, update.proof.c, inputs)) {
            revert("Failed to verify rotate proof.");
        }
    }

    function getSyncCommitteePeriod(uint256 slot) internal pure returns (uint256) {
        return slot / SLOTS_PER_SYNC_COMMITTEE_PERIOD;
    }

    function getCurrentSlot() internal view returns (uint256) {
        return (block.timestamp - GENESIS_TIME) / SECONDS_PER_SLOT;
    }

    function setHead(uint256 slot, bytes32 root) internal {
        if (headers[slot] != bytes32(0) && headers[slot] != root) {
            consistent = false;
            return;
        }
        head = slot;
        headers[slot] = root;
        emit HeadUpdate(slot, root);
    }

    function setExecutionStateRoot(uint256 slot, bytes32 root) internal {
        if (executionStateRoots[slot] != bytes32(0) && executionStateRoots[slot] != root) {
            consistent = false;
            return;
        }
        executionStateRoots[slot] = root;
    }

    function setSyncCommitteePoseidon(uint256 period, bytes32 poseidon) internal {
        if (
            syncCommitteePoseidons[period] != bytes32(0)
                && syncCommitteePoseidons[period] != poseidon
        ) {
            consistent = false;
            return;
        }
        syncCommitteePoseidons[period] = poseidon;
        emit SyncCommitteeUpdate(period, poseidon);
    }

    function setBestUpdate(uint256 period, LightClientRotate memory update) internal {
        bestUpdates[period] = update;
    }
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;
library PairingRotate {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
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
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
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
contract RotateVerifier {
    using PairingRotate for *;
    struct VerifyingKeyRotate {
        PairingRotate.G1Point alfa1;
        PairingRotate.G2Point beta2;
        PairingRotate.G2Point gamma2;
        PairingRotate.G2Point delta2;
        PairingRotate.G1Point[] IC;
    }
    struct ProofRotate {
        PairingRotate.G1Point A;
        PairingRotate.G2Point B;
        PairingRotate.G1Point C;
    }
    function verifyingKeyRotate() internal pure returns (VerifyingKeyRotate memory vk) {
        vk.alfa1 = PairingRotate.G1Point(20491192805390485299153009773594534940189261866228447918068658471970481763042,9383485363053290200918347156157836566562967994039712273449902621266178545958);
        vk.beta2 = PairingRotate.G2Point([4252822878758300859123897981450591353533073413197771768651442665752259397132,6375614351688725206403948262868962793625744043794305715222011528459656738731], [21847035105528745403288232691147584728191162732299865338377159692350059136679,10505242626370262277552901082094356697409835680220590971873171140371331206856]);
        vk.gamma2 = PairingRotate.G2Point([11559732032986387107991004021392285783925812861821192530917403151452391805634,10857046999023057135944570762232829481370756359578518086990519993285655852781], [4082367875863433681332203403145435568316851327593401208105741076214120093531,8495653923123431417604973247489272438418190587263600148770280649306958101930]);
        vk.delta2 = PairingRotate.G2Point([18334881142459210124015599747741974172927941011104160804888190975276338106928,20035455177528589591856590724829641064910039281803550322362302221054754197248], [17290993916376876703025978020731940903611933093571896886494881287155626742509,16174079257426575570222411523465728957771732853610323016780559234419705269561]);
        vk.IC = new PairingRotate.G1Point[](66);
        vk.IC[0] = PairingRotate.G1Point(12525868632291397536142172368598066922683658023057161272227576234482093132281,5672567757382168531788888504485934400581073111190756598133631661175270540096);
        vk.IC[1] = PairingRotate.G1Point(1371268021893866085937768870839922269734750615362202690675016208829681020919,18416477336927492195952192341596871707041385129232103297588426523414142810465);
        vk.IC[2] = PairingRotate.G1Point(9564356396332933093667470871829723402758203986241862789039455886895539893896,8134562031007647122919927099667025873051834234344231037762256728886696187036);
        vk.IC[3] = PairingRotate.G1Point(6490215069089281575827724970712215853662942592302922075583402763941130645427,17663847572931936197311636910864102979087052175028841670883334192195943672501);
        vk.IC[4] = PairingRotate.G1Point(19000095835032113882901426772286745386264947332617221959930279658350203747354,10667634516187039436345292953551272015601385906522286413447233034484053849987);
        vk.IC[5] = PairingRotate.G1Point(16884704789363609252460422614890365080042684682217181688790160821282044438454,12633744705791898956134630640223225183154695780580352204605981135198802150556);
        vk.IC[6] = PairingRotate.G1Point(7760374710584833797158600074619326054813563420576322005630249409315317220742,1682176036897380145000343415481567533399774650530921470730093346272544652087);
        vk.IC[7] = PairingRotate.G1Point(18360959029140264483941496842797830963392967415809061409194384827896763781778,14176097710894312587907633696423189601086529116058848114225512691506342702162);
        vk.IC[8] = PairingRotate.G1Point(19618563313824323132585313740606794619244553012493584603398089293898416379158,6759362918586536464092906176001076566491014039125144789964500800565023669576);
        vk.IC[9] = PairingRotate.G1Point(5128507327875429161556274698831637658614543204934895144167646265984582370923,2982974467438243346788319893949199026320627235861239148564795062482627406741);
        vk.IC[10] = PairingRotate.G1Point(2724154442664026613878027344431093183081855006072840293928265634048690081560,18118953790296521490185922303975062751002687192962785706924569542810412958258);
        vk.IC[11] = PairingRotate.G1Point(10976179361606427759747099662515749210583556776191193445504200309251563876,2321584074142709394784122014593572466529268909726924407144954044076635525352);
        vk.IC[12] = PairingRotate.G1Point(9656049828882551127650581760582163174494572696823869309015028262975942965867,15807076739514095619861684338390105794310966104730369009442129516266150737553);
        vk.IC[13] = PairingRotate.G1Point(6673601259025140607315027729069539854769269937640598241840096313365638633836,20210990450833016181737017336944811773547695948688292902592000506815998792923);
        vk.IC[14] = PairingRotate.G1Point(13015923765120603598820541462440316355489958110179441336545357885110073094158,3266622002455541839800667602238734811995782479100884004094967396168640431382);
        vk.IC[15] = PairingRotate.G1Point(3250886168340698790432013256281316479193511577458834075728172078321228991955,11538382115874991922566148693715758800127363233755904844190811876131720683848);
        vk.IC[16] = PairingRotate.G1Point(18597058988955954532117351990775332337854765536714587543384538667395847386850,9969211971125905780767990794686999269207514420449771417342556484366138384820);
        vk.IC[17] = PairingRotate.G1Point(19710364610010738080582690754635210882255918917434396580463242693568991108331,9560283678442588871368878439639585405400322483120603154222449415695342826496);
        vk.IC[18] = PairingRotate.G1Point(7727936401080399425100569335388330077940818246309649583479557835025621170987,13577387258309264276234220025518663931812674722091374971010083842586319087697);
        vk.IC[19] = PairingRotate.G1Point(7568764529632066591683125060931061043611525658691665552468985046964477253509,9975772232994063588226004854092211730169709563713135264376748325237790929980);
        vk.IC[20] = PairingRotate.G1Point(1689036661419235439947790042980325055476329214054667215001349162807366682744,8909419624475078351076757884656213234851623476379013535520198364200566026528);
        vk.IC[21] = PairingRotate.G1Point(14492027690962813638102156541557369056694337709239628416879106934135094005831,13851159013809791407305862298095886267142743738838673866586546569581029337167);
        vk.IC[22] = PairingRotate.G1Point(21272905593775494594950039610992738156464666585074181861287131496577529505769,19449430381224574365496524153880772068473842559359173564657678871646927942235);
        vk.IC[23] = PairingRotate.G1Point(6035232550809123222405425786612313603232759911883279890594308418986995528844,21693241290934532159787176276822164102377714529779794065641127923777851544368);
        vk.IC[24] = PairingRotate.G1Point(16488305745967525454591229399820449038854382687161580942193290517362276835677,10252090021443092551397122119415109967994186537690466344386081767114184641427);
        vk.IC[25] = PairingRotate.G1Point(8473312476907258247860856491253429286116194696052265504823080457357413125622,4788093826352218760471058573393378853196076385009690508939994942545876743851);
        vk.IC[26] = PairingRotate.G1Point(3031305176490726263794473040939116967031031880593520801031947199687879966874,14999920110955478110305728564466162627703832605462254584662476547715504577074);
        vk.IC[27] = PairingRotate.G1Point(16444736775784003470610902113923272613139540385991375429696473228723509429375,3700800333888441521899633421131845218026424730101746094959693110970980100727);
        vk.IC[28] = PairingRotate.G1Point(18772297627089645051161583835724951021027364460780474831077249422010303146653,3536594939516048071561666255845484075999386108912250670951713520393658500696);
        vk.IC[29] = PairingRotate.G1Point(21594060539826308211532325197517461179291489526212581474760349353381397943302,19737732959463672983089613806623468730295090985672951401184922023510781747746);
        vk.IC[30] = PairingRotate.G1Point(18664450430610693948280732070267285438514109281437357973588789663703181467841,10906036630713539537735114781304743861661611204702777177566728941431920317977);
        vk.IC[31] = PairingRotate.G1Point(2380402345637582198479233023866397727659877334484019138077252586044433067396,2609473104041551681950710890567156138294521518026292170034916261109429527095);
        vk.IC[32] = PairingRotate.G1Point(11065152812963881356841848966902378180622160189943998916782069158199061867966,20671499846108532227282752520901126177371547055176711718427665961066396143935);
        vk.IC[33] = PairingRotate.G1Point(20469081244156287336577152973619834797725380846437107580783565752173439843453,8822206713543679434992272499958806018651964845127670052812418196778643318073);
        vk.IC[34] = PairingRotate.G1Point(958742168512776581624949464258353545878826924833825377728585389139818358370,13393896627764501423026691068330839431470571891241741962631920260611128549704);
        vk.IC[35] = PairingRotate.G1Point(20013528120288200055645624768575005219796175055260002992172357285271309178563,8349362766267335699250193714443596425565168650826023503616721812030527133310);
        vk.IC[36] = PairingRotate.G1Point(15427553218350650866755989084543884174991229238631768116406551686801570523257,2627015974849201675190140634642031629299588546108337250836370170280497666881);
        vk.IC[37] = PairingRotate.G1Point(3655453434985744345705248126266506895943894694538965907718268347092160332302,12610597125378508121366596077866746605297943302520229582833856822257173478723);
        vk.IC[38] = PairingRotate.G1Point(19413497835004835500592089220607291116694421736018594144108374880529050726344,15342176265061889350267453508127035616278777203988546985819036205507252293508);
        vk.IC[39] = PairingRotate.G1Point(11059315656570734975313835882944584972801344004413327375070522675557115210501,17299526777098035179862356149932928091819238913977056057311978238581818337668);
        vk.IC[40] = PairingRotate.G1Point(12665419022805220259807160019236456782139238930748007904428700272548707662498,4089364601319286544226692386994287144841178792610468811884926940064639754099);
        vk.IC[41] = PairingRotate.G1Point(13457737350210746747770316133857628681893057380605589124411142830400091428807,13173270894916724253939792512735011593076060341084479974404128684850199192625);
        vk.IC[42] = PairingRotate.G1Point(7433571577200949936595436501824132309044433670105192358430706524852687195361,12880005548856641501783455527375710415188076167794764192459119368397794451202);
        vk.IC[43] = PairingRotate.G1Point(8482212181955669455155532760604057155532929124826624565557616634292314920707,11873238063393692786968110384990194174385555988769787985466216299642588637302);
        vk.IC[44] = PairingRotate.G1Point(722961969754186553049357954623228371215851931087920147814730648672921589068,8673520903136665500112819965524091539750944140157196580996212275885105769382);
        vk.IC[45] = PairingRotate.G1Point(7283317013047511298879484981761309252669837431108048947558927693919190914130,18132006196104738671848855099004376791714705858306950528918993011260756836487);
        vk.IC[46] = PairingRotate.G1Point(3117337241348462277930284659286129612701036034779361657031876819457391510792,8112513700689247723489882926249561541125523016585248589901301669358370317868);
        vk.IC[47] = PairingRotate.G1Point(13323702884342161635146603902200004540647717135752577752853553599442644903283,11420903390197842397460457478422776085659423759770597326545208049209060708490);
        vk.IC[48] = PairingRotate.G1Point(15795724369960429559292041953012957100182913478538317274722160606845774839480,4262038141053648133530604174085531744384476279403914477260254903195139682279);
        vk.IC[49] = PairingRotate.G1Point(20506722473551113298534310484164840361885347472653983474375420497039675177313,6701857291115501143077934422430908263994690201344307215951700497761443122367);
        vk.IC[50] = PairingRotate.G1Point(1249006434446242745017756511193515463940292706471525867379487857449199582968,9582852812340136653469263664834383384503045479937171681104573804801495905252);
        vk.IC[51] = PairingRotate.G1Point(17028470232660933140248512641680586692231467160440719185553322255200117023931,20532652837086406131186225540938949707656023893632697087455460786879372766574);
        vk.IC[52] = PairingRotate.G1Point(13612710665379649562723071846860410255445883622336445134244542614307608809936,16449462249558327847617872781937973447378046932933769094063121972557375651418);
        vk.IC[53] = PairingRotate.G1Point(12282820210482856534620028697640981175605233510208736513790350688138896134404,9251754013349530908678123608326008142245685615347942473706901548012375929170);
        vk.IC[54] = PairingRotate.G1Point(17523608970305102642888666291506098755735973601180269453446472185593289356976,12921073874395421708697074696323640413492067644824944863225245081530088882111);
        vk.IC[55] = PairingRotate.G1Point(4539082505871263014585329261790709819976038006165957435872478328010336827537,6954608923859835881276676523156310838283392568522178122343627921822524056670);
        vk.IC[56] = PairingRotate.G1Point(9084895949595785101743803823399777953885840679366088827984833088227203224468,16210791738035681411850393713754086658063691510220085984333301465456249692435);
        vk.IC[57] = PairingRotate.G1Point(20350862045584240245131666879058390224910054142060843851897763348878207632407,7047961129586520490252484140562962936914197872327183762644110360923657338391);
        vk.IC[58] = PairingRotate.G1Point(10547976271871978739395882303286527381139554311304506285048357334491623703627,16080980668415085781041764743333293604024754319404823390909868939277878316515);
        vk.IC[59] = PairingRotate.G1Point(11008708545148209282709342287100049475698556101099728497926874375710938456857,10224171278070630691003035912326880552945716613427699828174196950415608385144);
        vk.IC[60] = PairingRotate.G1Point(18144889991492010809363778101302670601807485847475061496889187222536071096117,7954007301574251444155563657753237310626329292056287284007165129148719870593);
        vk.IC[61] = PairingRotate.G1Point(18840331382975384454743083901622611062322647210798856612493296033704312301477,2344676710824357989856436915602218144893721294941925034096899342473253418740);
        vk.IC[62] = PairingRotate.G1Point(7805233659324124475581108166607620119573519583110322240792257615265040742664,20427933293472100390390250847828662861350114046237076571536728934528498690185);
        vk.IC[63] = PairingRotate.G1Point(3218010885754738946918188811690116972050797252265273231474588171495759954410,21564419819208391970907917351441563919143949569185247043244730303190619142835);
        vk.IC[64] = PairingRotate.G1Point(8375577873975643493053349502631883738318152826885528433351713925976598294071,11402213953238523714988092875945477353108340157525422385147435608912515260116);
        vk.IC[65] = PairingRotate.G1Point(19507381847058149568190573342886984515956234499207594621036432934248670760874,15223899520863868619061425810863357468721268744726949839470151671540717462809);

    }
    function verifyRotate(uint[] memory input, ProofRotate memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKeyRotate memory vk = verifyingKeyRotate();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        PairingRotate.G1Point memory vk_x = PairingRotate.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = PairingRotate.addition(vk_x, PairingRotate.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = PairingRotate.addition(vk_x, vk.IC[0]);
        if (!PairingRotate.pairingProd4(
            PairingRotate.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProofRotate(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[65] memory input
        ) public view returns (bool r) {
        ProofRotate memory proof;
        proof.A = PairingRotate.G1Point(a[0], a[1]);
        proof.B = PairingRotate.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingRotate.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verifyRotate(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
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
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;
library PairingStep {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
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
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
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
contract StepVerifier {
    using PairingStep for *;
    struct VerifyingKeyStep {
        PairingStep.G1Point alfa1;
        PairingStep.G2Point beta2;
        PairingStep.G2Point gamma2;
        PairingStep.G2Point delta2;
        PairingStep.G1Point[] IC;
    }
    struct ProofStep {
        PairingStep.G1Point A;
        PairingStep.G2Point B;
        PairingStep.G1Point C;
    }
    function verifyingKeyStep() internal pure returns (VerifyingKeyStep memory vk) {
        vk.alfa1 = PairingStep.G1Point(20491192805390485299153009773594534940189261866228447918068658471970481763042,9383485363053290200918347156157836566562967994039712273449902621266178545958);
        vk.beta2 = PairingStep.G2Point([4252822878758300859123897981450591353533073413197771768651442665752259397132,6375614351688725206403948262868962793625744043794305715222011528459656738731], [21847035105528745403288232691147584728191162732299865338377159692350059136679,10505242626370262277552901082094356697409835680220590971873171140371331206856]);
        vk.gamma2 = PairingStep.G2Point([11559732032986387107991004021392285783925812861821192530917403151452391805634,10857046999023057135944570762232829481370756359578518086990519993285655852781], [4082367875863433681332203403145435568316851327593401208105741076214120093531,8495653923123431417604973247489272438418190587263600148770280649306958101930]);
        vk.delta2 = PairingStep.G2Point([6334839042107130023049340792339379679848898684816656861828350368391491664199,3317270213410838920294110845504738187833260387085520528957722580763401366960], [8406083817439650896592130078113295489604824337161649591897794411839417245597,17769843424183241943445574279582311080656091170585266224532579755190305778591]);
        vk.IC = new PairingStep.G1Point[](2);
        vk.IC[0] = PairingStep.G1Point(13110779489797904532969126578151540824882803531996964478328346310227302758062,3881593380487042572953530587796685234564582042874576403150255687581846007102);
        vk.IC[1] = PairingStep.G1Point(17153446114235020416531614278119549782979248003554901970621794166089157865247,2467274125823591332750943468513596098407132637843839608018463922329819752865);

    }
    function verifyStep(uint[] memory input, ProofStep memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKeyStep memory vk = verifyingKeyStep();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        PairingStep.G1Point memory vk_x = PairingStep.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = PairingStep.addition(vk_x, PairingStep.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = PairingStep.addition(vk_x, vk.IC[0]);
        if (!PairingStep.pairingProd4(
            PairingStep.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProofStep(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool r) {
        ProofStep memory proof;
        proof.A = PairingStep.G1Point(a[0], a[1]);
        proof.B = PairingStep.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingStep.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verifyStep(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

pragma solidity 0.8.14;

interface ILightClient {
    function head() external view returns (uint256);

    function executionStateRoots(uint256 slot) external view returns (bytes32);

    function headers(uint256 slot) external view returns (bytes32);
}

pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
}

library SSZ {
    function toLittleEndian(uint256 x) internal pure returns (bytes32) {
        bytes32 res;
        for (uint256 i = 0; i < 32; i++) {
            res = (res << 8) | bytes32(x & 0xff);
            x >>= 8;
        }
        return res;
    }

    function restoreMerkleRoot(bytes32 leaf, uint256 index, bytes32[] memory branch)
        internal
        pure
        returns (bytes32)
    {
        bytes32 value = leaf;
        for (uint256 i = 0; i < branch.length; i++) {
            if ((index / (2 ** i)) % 2 == 1) {
                value = sha256(bytes.concat(branch[i], value));
            } else {
                value = sha256(bytes.concat(value, branch[i]));
            }
        }
        return value;
    }

    function isValidMerkleBranch(bytes32 leaf, uint256 index, bytes32[] memory branch, bytes32 root)
        internal
        pure
        returns (bool)
    {
        bytes32 restoredMerkleRoot = restoreMerkleRoot(leaf, index, branch);
        return root == restoredMerkleRoot;
    }

    function sszBeaconBlockHeader(BeaconBlockHeader memory header)
        internal
        pure
        returns (bytes32)
    {
        bytes32 left = sha256(
            bytes.concat(
                sha256(
                    bytes.concat(toLittleEndian(header.slot), toLittleEndian(header.proposerIndex))
                ),
                sha256(bytes.concat(header.parentRoot, header.stateRoot))
            )
        );
        bytes32 right = sha256(
            bytes.concat(
                sha256(bytes.concat(header.bodyRoot, bytes32(0))),
                sha256(bytes.concat(bytes32(0), bytes32(0)))
            )
        );

        return sha256(bytes.concat(left, right));
    }

    function computeDomain(bytes4 forkVersion, bytes32 genesisValidatorsRoot)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(uint256(0x07 << 248))
            | (sha256(abi.encode(forkVersion, genesisValidatorsRoot)) >> 32);
    }
}