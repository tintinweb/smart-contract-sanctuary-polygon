// SPDX-License-Identifier: MIT

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
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero
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
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {
        uint256[4] memory input = [
            p1.X, p1.Y,
            p2.X, p2.Y
        ];
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-add-failed");
    }

    /*
     * @return r the product of a point on G1 and a scalar, i.e.
     *         p == p.scalarMul(1) and p.plus(p) == p.scalarMul(2) for all
     *         points p.
     */
    function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input = [p.X, p.Y, s];
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
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
    ) internal view returns (bool) {
        uint256[24] memory input = [
            a1.X, a1.Y, a2.X[0], a2.X[1], a2.Y[0], a2.Y[1],
            b1.X, b1.Y, b2.X[0], b2.X[1], b2.Y[0], b2.Y[1],
            c1.X, c1.Y, c2.X[0], c2.X[1], c2.Y[0], c2.Y[1],
            d1.X, d1.Y, d2.X[0], d2.X[1], d2.Y[0], d2.Y[1]
        ];
        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, mul(24, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }
}

contract Verifier {
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[7] IC;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(14345256404360493565272253657934807283405829181387331365165557211859836148166), uint256(11977956733738130780475141929012474240871127468171679163520368079393731295267));
        vk.beta2 = Pairing.G2Point([uint256(5599017880877831612811288228082397526654512113747353636226171907833304823672), uint256(14014297725555610897950284585612371290497488931124864721931797052920982437814)], [uint256(20100476247142003573018803721667773303244247257021538679807469408045260077581), uint256(18971416153108283174078281946413540733835321252887831832784596223658046813719)]);
        vk.gamma2 = Pairing.G2Point([uint256(8096759334593027943501905206345424072412107167823600329229548990585225718281), uint256(2252414668614761167895950278246078464802722647647602902704353768489943293276)], [uint256(519047343384481173396234164245051717403232842120442450064455004633668824500), uint256(19583034061316304976430986544715985295759323068907540001709599930285828061723)]);
        vk.delta2 = Pairing.G2Point([uint256(11419523703570874798229818932906420619113294974784155398864792164896706752015), uint256(2018317165207901445185489795730479101143834144994979970743765840856650308835)], [uint256(18142633339366135856736696780299327523706703601572253799408363186927783684874), uint256(15816681688069370270011946079037939591245668820062012056490249903357199890497)]);
        vk.IC[0] = Pairing.G1Point(uint256(20603347426153754782758600748962504067138558111067512719043483090960431483857), uint256(18831544314817911659181628908355935284999496666179597944500543136289730220157));
        vk.IC[1] = Pairing.G1Point(uint256(4138461560074249848249862981363738431077701855389929937155214197991657407771), uint256(4253096159188460342932265672146647050401064188314359497316614845044210818258));
        vk.IC[2] = Pairing.G1Point(uint256(21364769914606092955683909152937343575339258347854967779489013255332186464161), uint256(14975988048949949042394227572329360382716389029480861744004924822198607424906));
        vk.IC[3] = Pairing.G1Point(uint256(9638563467242491451079253801884818950638773085269354274039348909525026409390), uint256(3291757185287304664980018815292739064698760695058988034616217103872479085146));
        vk.IC[4] = Pairing.G1Point(uint256(11708610223794570891913336243759600234129940282771086476837326259202367652854), uint256(16126489061713918098371527302521765459353771498710607800439516600777192818331));
        vk.IC[5] = Pairing.G1Point(uint256(5071241403476242753845212949532596194358523911594955352028655304008515559827), uint256(12055991769037283727539453395740609270890958922437809849673820297803852191267));
        vk.IC[6] = Pairing.G1Point(uint256(1729976383997923727783840634609073180025912513144454001578635498051163843049), uint256(4819638389443932461540912575965348369462621635999319930966067312965979220498));

    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        bytes memory proof,
        uint256[6] memory input
    ) public view returns (bool) {
        uint256[8] memory p = abi.decode(proof, (uint256[8]));
        for (uint8 i = 0; i < p.length; i++) {
            // Make sure that each element in the proof is less than the prime q
            require(p[i] < PRIME_Q, "verifier-proof-element-gte-prime-q");
        }
        Pairing.G1Point memory proofA = Pairing.G1Point(p[0], p[1]);
        Pairing.G2Point memory proofB = Pairing.G2Point([p[2], p[3]], [p[4], p[5]]);
        Pairing.G1Point memory proofC = Pairing.G1Point(p[6], p[7]);

        VerifyingKey memory vk = verifyingKey();
        // Compute the linear combination vkX
        Pairing.G1Point memory vkX = vk.IC[0];
        for (uint256 i = 0; i < input.length; i++) {
            // Make sure that every input is less than the snark scalar field
            require(input[i] < SNARK_SCALAR_FIELD, "verifier-input-gte-snark-scalar-field");
            vkX = Pairing.plus(vkX, Pairing.scalarMul(vk.IC[i + 1], input[i]));
        }

        return Pairing.pairing(
            Pairing.negate(proofA),
            proofB,
            vk.alfa1,
            vk.beta2,
            vkX,
            vk.gamma2,
            proofC,
            vk.delta2
        );
    }
}