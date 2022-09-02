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
        vk.alfa1 = Pairing.G1Point(uint256(18944220228912279980466259922678911229954338135903988035925552737212194500738), uint256(20900391422802270883235919368827566283946283165442797764465294874142521190008));
        vk.beta2 = Pairing.G2Point([uint256(21386715541565910917002665548866586807663538760856454443508097103844758923001), uint256(3809782516247994409830561942915237554292486089985267965095496339013804706057)], [uint256(8248621225026338947313116807976135959024559144843352645770432227818475744318), uint256(2266716113197877056487956489151053826279429032675122961043467649540003982446)]);
        vk.gamma2 = Pairing.G2Point([uint256(15177928260427108251159186668335019353961623531621767148692285158289837276720), uint256(14347336203138369560133834203800073391392195213900852785097010413189889230345)], [uint256(7340424286520462771875993254300805278557420717992362701298576610741245513549), uint256(1999683320108104241712648568010502596456207185710756952391059230928184529801)]);
        vk.delta2 = Pairing.G2Point([uint256(15204415379140157898513940613995963437984583743784317173828951519637642013196), uint256(2700875197706924599198534269531353203663771709027311185139459048159820368150)], [uint256(15547486120176378680120953170760536701028497780350538173055626139013894580355), uint256(11721156526983396046958777698076676580150102201414196554223311647332556311608)]);
        vk.IC[0] = Pairing.G1Point(uint256(5801318814824130730117822413913067293784281522137018144792779118596857549800), uint256(21509340737485647671643962628088827897320012888881208783128488133445602100145));
        vk.IC[1] = Pairing.G1Point(uint256(8669792294722488737976224572845451713915132161067343350465203556639744743016), uint256(13377960051996683699324036908986947225568058007379678055137825607232547599406));
        vk.IC[2] = Pairing.G1Point(uint256(2438610506675461627194139941901398061772545803703885006347939589487178004824), uint256(9757345819926584250435893205494878104981778270220141071974674032961042879762));
        vk.IC[3] = Pairing.G1Point(uint256(10671704515914382417727949531792185211210020701850904913184853296914794649796), uint256(9137382561466853675381994203130277701430357826918751702927957637930409246803));
        vk.IC[4] = Pairing.G1Point(uint256(18081682696764173184537074970193243841195650820178546646199923192860868037646), uint256(17324698339131988300406012826427197149238735284130971516773010862644257418125));
        vk.IC[5] = Pairing.G1Point(uint256(754329880829347699868667265430053661924918436757254333622606318122136109229), uint256(13724245722980952435193443893890756268575761461502456160483407765442499012102));
        vk.IC[6] = Pairing.G1Point(uint256(21265815839099000228899566675234110019680388309430587065329179332356257204172), uint256(14048234678071801596117666193525088245226719514713451545053080763251624036407));

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