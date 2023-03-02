/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

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
    }

    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }

    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory r)
    {
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

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint256 s)
        internal
        view
        returns (G1Point memory r)
    {
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
    function pairing(G1Point[] memory p1, G2Point[] memory p2)
        internal
        view
        returns (bool)
    {
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
            success := staticcall(
                sub(gas(), 2000),
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
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

contract Verifier {
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

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            19588571812112913444313220207184812430901027328814934314041336494389579727490,
            20876620758613883198678971399947228020349152495363712824452439555681722703844
        );

        vk.beta2 = Pairing.G2Point(
            [
                1147493305972264361212333694047172493748629835776584342561122245368117789090,
                15546110242127298774725801171866202053855864729583087780269711803018153583170
            ],
            [
                15670534484052726488703126009147413779716090823943941203768509391720636478498,
                13018026423551894160093592214570497989649376948777150787778860795428582397888
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                14502308529068562960482656727141207655910101847204149533190076802856916253544,
                19564662523331646217337334776200297798706313172317028914539039054142262951344
            ],
            [
                19322636740713750153562137600202408323948637463899977496356907007307802584587,
                1859245150258807714578483262611774465897891037769776678764335798540115311482
            ]
        );
        vk.IC = new Pairing.G1Point[](18);

        vk.IC[0] = Pairing.G1Point(
            4644302044163333633193668138034373579414780561355523521723820139850096127065,
            132535718064324173610843892132061711715429019920237103560054147710479734773
        );

        vk.IC[1] = Pairing.G1Point(
            14554669171440115333844386954501235788482823021448975290988850856000453137445,
            15002479857639310915298102325332865643131837488227837028042726097524180093326
        );

        vk.IC[2] = Pairing.G1Point(
            15370991053439701469942838257923255079256254046451912781889016072148452485672,
            4176615531706953255626978772143037677602892540361958067692355765102082357337
        );

        vk.IC[3] = Pairing.G1Point(
            20539785643982557478026712029584933401021503864766142111582958110590338700112,
            19430995276710238415684904893655769876439459251929521375243707806372117590784
        );

        vk.IC[4] = Pairing.G1Point(
            11725685233460118159820907864104231439876089430389909065313281206385414507032,
            16056476202664483182329846818982632736942122561947765687868922709091562559291
        );

        vk.IC[5] = Pairing.G1Point(
            21695831149408299634922629842817243220085005611590226615671048250162614655184,
            18648672120444705458764496847005342365239328095925993823328308608649954726254
        );

        vk.IC[6] = Pairing.G1Point(
            2271110670428055567263028240342058037482103864212879985810985403598999273706,
            12997413602519288510713962115597272724990022604286736132673962433801246000049
        );

        vk.IC[7] = Pairing.G1Point(
            18343737722410686590178463933407560801826990291159516138870655023837236454386,
            5060651789061501225716561747808622063433612419601620777445629673430574614825
        );

        vk.IC[8] = Pairing.G1Point(
            11518482939170289486754265733952727297782112382492490810094334870020430476840,
            11048428986216303472170333660651625309899038238690847000913234477377756198354
        );

        vk.IC[9] = Pairing.G1Point(
            10767153191540959885762408168351920205686132146086701867538812095784207407809,
            480036892345808583214857114547714816060283901653328559653954993510898823909
        );

        vk.IC[10] = Pairing.G1Point(
            336114676963785838441014648216337192305629155434336421248213369993624926457,
            216079891848391936525210061899404833866118143577240207687006500026219727089
        );

        vk.IC[11] = Pairing.G1Point(
            5939643244813210302133397993610876567210952368856885383167455483088364830979,
            5505317684091419746092577478581993752834987705141079168705726218790237730928
        );

        vk.IC[12] = Pairing.G1Point(
            5805951290615465405718293708580383126620201949982812989225375155995451738777,
            8879647661617174987046207571048295892423326283958683499039540288674172540770
        );

        vk.IC[13] = Pairing.G1Point(
            5946254426584511361439725352027427168161861235008733552901212652599306121563,
            9694751706916623990571562094159679421936257088365418036843450226070685620992
        );

        vk.IC[14] = Pairing.G1Point(
            21558597461063231518312188386625299310859850517010321926880286706724343215404,
            2622528610726282086389269575855668158862410787889296736214992639313799452084
        );

        vk.IC[15] = Pairing.G1Point(
            14016077367638741466906863513819094500952467638916525284608320156527897015872,
            2800367344608083542014367806924511209810351685365595004988390829131180253375
        );

        vk.IC[16] = Pairing.G1Point(
            7083531183518299055528755501641715584641206369801444800294447992588260177205,
            17560794771640656181857507672170822811323764420402375988818933624397975190779
        );

        vk.IC[17] = Pairing.G1Point(
            18303669516366849880986497067732709432571836721574521624438124669702263289311,
            5447274593936750119188702475306374856446500173093805160656987650356707635449
        );
    }

    function verify(uint256[] memory input, Proof memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
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

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[17] memory input
    ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

contract ZKRollup is Verifier {
    uint256 public maxTx = 10000; // max number of transactions a batach can have. will not use it for now. when use it, one new constructor will be added to limit transactions.
    uint256 public nLevels = 4; // levels of merkle root. circom file ka merkle tree vale code me nLevels hai vahi rahega yaha. ⌛. don't know how to use it yet.
    uint256 public lastBatchStateRoot = 0;
    uint256 public batchNumber = 0;
    uint256[] public batchesRoots;

    // ownership/admin control
    address public owner;

    constructor() {
        owner = msg.sender; // ⌛ multi owner: in case of decetralised sequencer
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Rollup::forgeBatch: only permitted peoples allowed"
        );
        _;
    }

    // zk: proof
    // struct proof {
    //     uint256[2] a;
    //     uint256[2][2] b;
    //     uint256[2] c;
    //     uint256[17] input;
    // }

    // only allow if sender verify proof by providing right proofs
    // modifier proofToUpdata(proof memory _proof) {
    //     require(
    //         verifyProof(_proof.a, _proof.b, _proof.c, _proof.input),
    //         "Rollup::forgeBatch: proofs not verified"
    //     );
    //     _;
    // }

    // new batch data in event form
    event stateUpdata(
        uint256 batchNumber,
        uint256 merkleStateRoot,
        uint256 updationTime,
        // proof _proof
        uint256[2] a,
        uint256[2][2] b,
        uint256[2] c,
        uint256[17] inputf
    );

    // forgeBatch / updateState / newRootUpdate / newStateUpdate / newBatchUpload
    function forgeBatch(
        uint256 newBatchNumber,
        uint256 newStateRoot, // ⌛: marybe one more root will come
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[17] memory inputf,
        bool l2Batch
    )
        public
        onlyOwner
        returns (
            // proofToUpdata()⌛
            bool
        )
    {
        // require(
        //     verifyProof(a, b, c, inputf),
        //     "ZK proofs not verified, INSERT PROPER INPUTS"
        // );
        // verifyProof(__proof.a,__proof.b,__proof.c,__proof.input),

        // admin need to tell batch number and confirm its l2Batch before uploading new batch data
        if (newBatchNumber != batchNumber && l2Batch) {
            return false;
        }

        batchNumber++;
        batchesRoots.push(newStateRoot);
        lastBatchStateRoot = newStateRoot;

        uint256 currentTime = block.timestamp;

        // emit event to save new batch data
        emit stateUpdata(
            newBatchNumber,
            newStateRoot,
            currentTime,
            a,
            b,
            c,
            inputf
        );

        return true;
    }
}