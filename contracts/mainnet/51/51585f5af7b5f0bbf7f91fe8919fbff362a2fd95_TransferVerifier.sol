pragma solidity ^0.6.0;

library Pairing {
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
        * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
        */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
        * @return r the sum of two points of G1
        */
    function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
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
            case 0 { invalid() }
        }
        require(success, "pairing-add-failed");
    }

    /*
        * @return r the product of a point on G1 and a scalar, i.e.
        *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
        *         points p.
        */
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
            case 0 { invalid() }
        }
        require(success, "pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
        *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
        *         For example,
        *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
        */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    )
        internal
        view
        returns (bool)
    {
        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }
}

contract TransferVerifier {
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[6] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            17259644642628619054198707088350178151915223546531204588599012585652862256289,
            6538916430504110934790598121254623711490867458521598147771684120236145100336
        );
        vk.beta2 = Pairing.G2Point(
            [
                uint256(11097434194162826858949644387544008701579694224939913271486290330733219134420),
                6010942275679443033856179065724641913553695310529001864983746063540149145812
            ],
            [
                uint256(19013261012401115818773510381885163557486260979365651129010452890236255493703),
                11314427763437581543307480788475949801872673194176472756000669236569465847384
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                uint256(11559732032986387107991004021392285783925812861821192530917403151452391805634),
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                uint256(4082367875863433681332203403145435568316851327593401208105741076214120093531),
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                uint256(2902637713278292258811651154412359018005901436491303180110684723456248804269),
                7484528799857450808065255942134606119430029155634760331759295849741156906855
            ],
            [
                uint256(16919380294118021238188351633827806325631876098638790471756828559280597972661),
                15879928641047093337781309621554568931772184254392936691886872718125787059079
            ]
        );
        vk.IC[0] = Pairing.G1Point(
            6751687213449187034022596630956335633982483843297162924909869215591126015733,
            3332988954367257098898387790785575687011068005490583766955064476643031117631
        );
        vk.IC[1] = Pairing.G1Point(
            582960571249415776815021408300527948585998932543552257654890418553663373076,
            20175439176763881632810898254658720545091242686088320863343010376851556767424
        );
        vk.IC[2] = Pairing.G1Point(
            3313530483045122798552725078041077120526052456782205997701993938573932045238,
            18587493607708423879798372956595948413056322630510266882373940927660680877483
        );
        vk.IC[3] = Pairing.G1Point(
            16606694823609835077648315592888416783515366330883944893969234268731221395566,
            1298850705085093616855740420452097478911720727510680465133425500898480783863
        );
        vk.IC[4] = Pairing.G1Point(
            4018812531419306579964082476182684599524329135659966591147842116740619128821,
            9583801151216438145036599103273866437768557943669777940412307006387046824384
        );
        vk.IC[5] = Pairing.G1Point(
            11566287213388117430184214310307782070408497124066240068190823297199328432542,
            851698791906486596877962237141665075280064687760364445639543982438186381156
        );
    }

    /*
        * @returns Whether the proof is valid given the hardcoded verifying key
        *          above and the public inputs
        */
    function verifyProof(uint256[5] memory input, uint256[8] memory p) public view returns (bool) {
        // Make sure that each element in the proof is less than the prime q
        for (uint8 i = 0; i < p.length; i++) {
            require(p[i] < PRIME_Q, "verifier-proof-element-gte-prime-q");
        }
        Proof memory _proof;
        _proof.A = Pairing.G1Point(p[0], p[1]);
        _proof.B = Pairing.G2Point([p[3], p[2]], [p[5], p[4]]);
        _proof.C = Pairing.G1Point(p[6], p[7]);
        VerifyingKey memory vk = verifyingKey();
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        vk_x = Pairing.plus(vk_x, vk.IC[0]);
        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD, "verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        return Pairing.pairing(Pairing.negate(_proof.A), _proof.B, vk.alfa1, vk.beta2, vk_x, vk.gamma2, _proof.C, vk.delta2);
    }
}