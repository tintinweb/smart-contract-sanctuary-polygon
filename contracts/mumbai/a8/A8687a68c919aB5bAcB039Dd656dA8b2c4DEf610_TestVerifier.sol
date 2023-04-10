// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

library PairingLib {
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

// TODO update to new Semaphore verifier:
// https://github.com/semaphore-protocol/semaphore/pull/96
// by using the following template:
// https://github.com/semaphore-protocol/semaphore/blob/main/packages/contracts/snarkjs-templates/verifier_groth16.sol.ejs

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../libs/PairingLib.sol";

/// @title Test Verifier interface.
/// @dev Interface of Test Verifier contract.
interface ITestVerifier {
    error InvalidProof();
    
    struct VerifyingKey {
        PairingLib.G1Point alfa1;
        PairingLib.G2Point beta2;
        PairingLib.G2Point gamma2;
        PairingLib.G2Point delta2;
        PairingLib.G1Point[] IC;
    }
    
    struct Proof {
        PairingLib.G1Point A;
        PairingLib.G2Point B;
        PairingLib.G1Point C;
    }

    /// @dev Verifies a Test proof.
    /// @param proof: SNARk proof.
    /// @param input: public inputs for the proof, these being:
    ///     - identityCommitmentIndex
    ///     - identityCommitment
    ///     - oldIdentityTreeRoot
    ///     - newIdentityTreeRoot
    ///     - gradeCommitmentIndex
    ///     - gradeCommitment
    ///     - oldGradeTreeRoot
    ///     - newGradeTreeRoot
    ///     - testRoot
    ///     - testParameters
    /// @param testHeight: height of the trees that define the test.
    function verifyProof(
        uint256[8] calldata proof,
        uint256[10] memory input,
        uint8 testHeight
    ) external view;
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
pragma solidity ^0.8.4;

import "../interfaces/ITestVerifier.sol";

contract TestVerifier is ITestVerifier {
    using PairingLib for *;

    // prettier-ignore
    // solhint-disable-next-line
    uint256[2][13][3] VK_POINTS = [[[12942333082934331728993750297006238721468756489273435836235037010830247467967, 4540856000900140503523131045700844883347004309759902770531971444702419824351],[10713220694634826273056820261569641268368527174836857361685017642659702029653, 20949021655794369342840475088782850199693117477619023432532419550901705553271], [3460062508552817020486925369254999887263133458813466217731827384934429097020, 6548713001085123926575038298695600145312927787528715550119079790931672327813], [15406797828010507507654709597514439821408759067336276943873336328717012977533, 19553210546637991787255561768764488682517242914620423299213539464848415485500], [19959185561623974415619877157902362479891361197065675787577508710528967104307, 13028996927053214837834749241659838061801532423651520178675227615459389210616], [3310347240584205286564761138090629394369593928734612543936801937448780301664, 10900500954734637634564926942755372709002521226615682563984323730454620350391], [11091680874613960967729951932578059385906300270392786135336684103353733583422, 6146308255966051074843231585072122380655579907379922519442391456269011084178], [12811880879583919745481239883357696952873392785587273972220422768150948251977, 15976546320593452163827813166385762914849060167442602352116206563021690783978], [2917197395052975746065400516817828630265365052212604569191665775907653974177, 396250047748014580988740073253604656528377721738973347967828983986117954433], [12998061194137106909055711176405500564127106907373634397320993374989305381375, 7255621895748584856490916992008717489392792541057649710461499089983416377929], [460068829744378908379382034907278053818690835649865283577316886454704782982, 15233131022588598198020254400449240943837285738025101436381461193692321940517], [12153453805862254887532530442049591861398122148589936265936185544407062280880, 3396208004435099672016900113424293135040725911842982531561263577435614395928], [19165359902719776689239202198859840978181559442556194502339828248740858897084, 16819584196418239971003086897134330161552719269824933476869323395879116632712]], [[13799269636296683296606767401406345079982820292452198697552704257624543012641, 20690472726591021362519659193214433501915763012434646907222090111895897337205],[15353599038576026736582313087219331610755245504320219019310807930224871707261, 21804394630166623203565424646571792889383518626770454011903731655501375857787], [6178464234645025990239182644324979979357561953686286605234926281137177884664, 9291658565583776240508675958722285223493046595400506971843052856530415834247], [20329971974906285278348186615764994642581024425455284387504519443430116790891, 142225138864615169879408649544585096057839319602539919981114183901521453136], [12623171699629737300906378653886128851448034854066489142429041377005317978920, 17069080619022065711219923821662655453612150277770462884723837833817492381063], [9731284393490251946100308731784140959024166737124061902931839160231930966901, 20254524038001575515881280820177994623409762212544003383046988676532278498927], [5035941612547139498310069971733200145167205385240372433350210591192909751799, 14951992849208002406655043406058274782529499511717817498586117622041233468138], [3996862283674922367742079866027143004837562259824041591377740374879907185515, 13118379756918589623188825996508305501105823913956921943983349874525657154539], [10130876028457216435169235410498857105814949264852246030309355622832656762655, 14645087973584550144770394515122830035173936873712904656915296407838137638736], [14497610756517999081256078843398820202264094921488556535798682424184552796020, 17452525492691218803120091373460174808503498342569308996167895143023592616795], [1567474941928983275970670186646466122189820153756155894008676963113496032970, 21311685603958880600568626311848420912386517813249054680916234132953994027651], [8686708691293511211182993765554144148459644581708895011228231954494204359636, 2084834714833666699039538063913997335999563691486801901240229861095689880900], [902184051864523737194207891910179342138897179853813433530804819669953673391, 17737121108843234527813362294770298533844024043256228414988320185580411027802]],[[3125629459637059195642800322175047277808135777449084766509794958094752100923, 16731607036563878758638686799985828639326992321132815167258641606364873979699], [21118753855998363853256096909047379452739378294072800652081001947270187627719, 985948279804942928834127099316114301578529641320781073608328905248635586566], [15701663590014921532921960813024076515886450481041981352973071644628957473885, 4029702578219577355115054213159511197918112798336489277312432195437629346817], [11411298893507778768336411773838968844659532549412067564558799462375959797095, 10883970276499694761788988875416554326109978475435934452151304707463117068975], [1657441127695113463529209762911849146841225886309275570893822196612029371732, 10874417601615041302352521596020387512033194820636514702063861556248080825588], [17607850747391341893026091408980065582429471212100689784395431754124259109194, 16688303949459255693399421892987011114075359691366181809552376455687109369446], [11572082814276390223512472734823186365819913031800277669751535038606453949292, 21525510712377249581951761853570902634635069971403517775817444904352008555342], [21204928170726277593552043219174579204073686950798675036234612605037073736476, 2659881797694149387503429734998373655623868181360190277682447753253710279594], [10772037888198166136018674235480352098674793982056761284820438114241261609126, 20182667549757899077322548004901568873857241075530987939066314357479282993026], [12337706999080323854295315910607030000381520032870032279255049676917325863519, 6972646636366142138679204120770062855354552378861769746846311381920140415565], [18940299556498154953678453716188790194410692603814034563696314566209848083753, 7803244552057865178378377026699298263752062733835846028274845474083602953132], [17088593136992153437302524853047591525887337200256155839884102126300941605365, 1803668846264618363435548357436383698719943509141728457626220829104269687018], [17738932611525213992745645311482081757330800695433582791577884618493521158673, 6032819592984899501611611506264574089620242223369852548605797584620768352928]]];
    
    function _getVerificationKey(uint8 vkPointsIndex) private view returns (VerifyingKey memory vk) {
        vk.alfa1 = PairingLib.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = PairingLib.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132, 6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679, 10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );

        vk.gamma2 = PairingLib.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634, 10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531, 8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

        vk.delta2 = PairingLib.G2Point(VK_POINTS[vkPointsIndex][0], VK_POINTS[vkPointsIndex][1]);

        vk.IC = new PairingLib.G1Point[](11);

        vk.IC[0] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][2][0], VK_POINTS[vkPointsIndex][2][1]);
        vk.IC[1] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][3][0], VK_POINTS[vkPointsIndex][3][1]);
        vk.IC[2] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][4][0], VK_POINTS[vkPointsIndex][4][1]);
        vk.IC[3] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][5][0], VK_POINTS[vkPointsIndex][5][1]);
        vk.IC[4] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][6][0], VK_POINTS[vkPointsIndex][6][1]);
        vk.IC[5] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][7][0], VK_POINTS[vkPointsIndex][7][1]);
        vk.IC[6] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][8][0], VK_POINTS[vkPointsIndex][8][1]);
        vk.IC[7] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][9][0], VK_POINTS[vkPointsIndex][9][1]);
        vk.IC[8] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][10][0], VK_POINTS[vkPointsIndex][10][1]);
        vk.IC[9] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][11][0], VK_POINTS[vkPointsIndex][11][1]);
        vk.IC[10] = PairingLib.G1Point(VK_POINTS[vkPointsIndex][12][0], VK_POINTS[vkPointsIndex][12][1]);                                  
    }
    
    function verifyProof(
        uint[8] calldata _proof,
        uint[10] memory input,
        uint8 testHeight
    ) external view override {
        Proof memory proof;
        proof.A = PairingLib.G1Point(_proof[0], _proof[1]);
        proof.B = PairingLib.G2Point([_proof[2], _proof[3]], [_proof[4], _proof[5]]);
        proof.C = PairingLib.G1Point(_proof[6], _proof[7]);

        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = _getVerificationKey(testHeight - 4);

        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        PairingLib.G1Point memory vk_x = PairingLib.G1Point(0, 0);
        for (uint i = 0; i < input.length; ) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = PairingLib.addition(vk_x, PairingLib.scalar_mul(vk.IC[i + 1], input[i]));
        
            unchecked {
                ++i;
            }
        }

        vk_x = PairingLib.addition(vk_x, vk.IC[0]);
        
        if (!PairingLib.pairingProd4(
            PairingLib.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) {
            revert InvalidProof();
        }
    }
}