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
        vk.alfa1 = Pairing.G1Point(uint256(5399101132970006606627925128037608517640705673689291100964797960804211844882), uint256(10345219764757062057450074117255161585534901831184598173843568786700918676112));
        vk.beta2 = Pairing.G2Point([uint256(18873319863434035528786119062393866692028106460277934849290521764890718417550), uint256(8346189766768460666898419142255332601569137835961060252977523946048648605518)], [uint256(7792889395104239255430936084043632161493541606314336974998950846721189477682), uint256(9649467381473000495336639262147839379327869628315842600874451033729613993597)]);
        vk.gamma2 = Pairing.G2Point([uint256(11932933414773572149902849247729105318303575775168865366411234267797034743719), uint256(1948413491078068786580753603711022291857872377056005921630227135410792805986)], [uint256(7275584562882604010062637421414324084426051960979916324187901618629883439084), uint256(6010174727173290975837544725889722738019970192910577324340686935598305634393)]);
        vk.delta2 = Pairing.G2Point([uint256(13948334007969526746218616721694173110622635667019630823111473293655197747813), uint256(17890431234397835104432611410504725787901785115635418931164361579162622288481)], [uint256(1860054656335532696878861086977300561106048951818656990809981764718632821390), uint256(6108839503913747891547579193763090624910575210207982230346172984075172934209)]);
        vk.IC[0] = Pairing.G1Point(uint256(20353982639728482837048752933558241446014618927907430300518596356741174633075), uint256(6418295179466844043428375311689317964670751188968811785608179054659010247112));
        vk.IC[1] = Pairing.G1Point(uint256(17858159882327734230205708578458873701488464647225161843210032591657229467618), uint256(5872415784842964411852259132184052601968823590290284018731561289293419264869));
        vk.IC[2] = Pairing.G1Point(uint256(7181386909712376661005924696107471503345180541772872701449731577859590470916), uint256(9649584099875158521479522674405083084427513880544579998442797591805695527180));
        vk.IC[3] = Pairing.G1Point(uint256(16826519297769529262116615314683238934137324578524697320750493257272690228381), uint256(8530896598531322983522841451326976555767823290613832939757053594210680260482));
        vk.IC[4] = Pairing.G1Point(uint256(13912240332567485609774285572441451409325791213366797021848396076937982203885), uint256(14207317632477617096864490377465076372056088007282917277474789740700846773118));
        vk.IC[5] = Pairing.G1Point(uint256(5480815728096820967395416269888424403422313071749984053319596804774558282607), uint256(12016855603536212161101713793247530563092778817877600272370405575027201207985));
        vk.IC[6] = Pairing.G1Point(uint256(7461105278703599861006230968970152332769267620612275375404107372401640868334), uint256(9351382053445093756111958274649445247734637332864855651408073211637260997122));

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