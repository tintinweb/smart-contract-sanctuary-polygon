// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./MerkleTree.sol";
import "./DepositVerifier.sol";

contract Wisp is MerkleTree {

    DepositVerifier public immutable depositVerifier;

    mapping(address => bool) public tokens;

    event Payment(uint256 publicKey, uint256 commitment, bytes encryptedData, uint32 index);

    constructor(
        uint8 _levels,
        address _hasher,
        address _verifier,
        address[] memory _tokens
    ) MerkleTree(_levels, _hasher) {
        depositVerifier = DepositVerifier(_verifier);

        for (uint8 i = 0; i < _tokens.length; i++) {
            tokens[_tokens[i]] = true;
        }
    }

    function deposit(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256 commitment,
        uint256 publicKey,
        uint256 amount,
        address token,
        bytes calldata encryptedData
    ) external {
        require(tokens[token], "Token is not supported");

        uint256 encryptedDataHash = uint256(keccak256(encryptedData)) % FIELD_SIZE;
        require(depositVerifier.verifyProof(a, b, c, [commitment, publicKey, amount, uint256(uint160(token)), encryptedDataHash]),
            "Deposit is not valid");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint32 index = insert(commitment);
        emit Payment(publicKey, commitment, encryptedData, index);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPoseidonHasher {
    function poseidon(uint256[2] calldata inputs) external pure returns (uint256);
}

contract MerkleTree {

    uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint8 public constant ROOT_HISTORY_SIZE = 30;

    IPoseidonHasher public immutable hasher;

    uint8 public levels;
    uint32 public immutable maxSize;

    uint32 public index = 0;
    mapping(uint8 => uint256) public levelHashes;
    mapping(uint256 => uint256) public roots;

    constructor(uint8 _levels, address _hasher) {
        require(_levels > 0, "_levels should be greater than 0");
        require(_levels < 32, "_levels should not be greater than 32");
        levels = _levels;
        hasher = IPoseidonHasher(_hasher);
        maxSize = uint32(2) ** levels;

        for (uint8 i = 0; i < _levels; i++) {
            levelHashes[i] = zeros(i);
        }
    }

    function insert(uint256 leaf) internal returns (uint32) {
        require(index != maxSize, "Merkle tree is full");
        require(leaf < FIELD_SIZE, "Leaf has to be within field size");

        uint32 currentIndex = index;
        uint256 currentLevelHash = leaf;
        uint256 left;
        uint256 right;

        for (uint8 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros(i);
                levelHashes[i] = currentLevelHash;
            } else {
                left = levelHashes[i];
                right = currentLevelHash;
            }

            currentLevelHash = hasher.poseidon([left, right]);
            currentIndex /= 2;
        }

        roots[index % ROOT_HISTORY_SIZE] = currentLevelHash;

        index++;
        return index - 1;
    }

    function isValidRoot(uint256 root) public view returns (bool) {
        if (root == 0) {
            return false;
        }

        uint32 currentIndex = index % ROOT_HISTORY_SIZE;
        uint32 i = currentIndex;
        do {
            if (roots[i] == root) {
                return true;
            }

            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        }
        while (i != currentIndex);

        return false;
    }

    // zero is poseidon(keccak256("wisp.finance") % FIELD_SIZE)
    function zeros(uint256 i) public pure returns (uint256) {
        if (i == 0) return 0x131d73cf6b30079aca0dff6a561cd0ee50b540879abe379a25a06b24bde2bebd;
        else if (i == 1) return 0x030e41eb4c13eb3c7040201a76ec17a95b0696ae684c8711f643a82434043b85;
        else if (i == 2) return 0x2de9e35e5e66734c46a160df81e56c83d8b7687ea37f6b4a27623a787127fad8;
        else if (i == 3) return 0x1ee3ac3d5ea557aa6d9a6ea46262dc42af62bae8c7864a9cc8dfb493d54bba30;
        else if (i == 4) return 0x0bef9271bdaa22ee892e75171bf1898983a6c8304ab78da111413a4105733219;
        else if (i == 5) return 0x1b4bb8a6696efaa2cd20d4b47bf9dc585280dec286f06aedd01583a58c783f51;
        else if (i == 6) return 0x2aabe03c18f20b72f67ade3063f12d71ad671d375d797ba60dfac9d924f02708;
        else if (i == 7) return 0x2daff101798c30998276c67457a7baaaaed141e6e49a2310deb01a71e3ec107d;
        else if (i == 8) return 0x1cafdb09713bb57e4aed4bee8f6d722a8e22c8ac51dafa7faf3b5585536b443e;
        else if (i == 9) return 0x1d585d8e6fa2b1698a000c733e3c2c8a6baaf40166f82ee0412a266496bab85f;
        else if (i == 10) return 0x2fa8177393423a5b0e68dbb8a555a9085464b5fe55219d377edb5a9a486b4f16;
        else if (i == 11) return 0x1e9dbba95cdde33d36bc0cee03f7ebeddd71cdc633451d996a9cb83bc4faccad;
        else if (i == 12) return 0x0adacfac36026ca9936dd2e4d540a947a1a2cb2ce7114ddcb24a3956eae54880;
        else if (i == 13) return 0x1b08cd6df6cbf993b04b8b2e40882ca9aa48ca3afb074b88e52963f1c63f534b;
        else if (i == 14) return 0x086043d5906d53b339d340d39738f2037541c5440073a481feb8b1f513b1f61e;
        else if (i == 15) return 0x06108b01607231776eb7debff2f99da31dd70f4bcbeccc251843de92456d9464;
        else if (i == 16) return 0x10f9e234e1bb3ab0c5e979c489e0f82b08b74f4177a6fc85e08e5aac314de30e;
        else if (i == 17) return 0x0432ad8ddfeffc1e806be483a4172fd3389aee0d322d5d0211da447be542dc1e;
        else if (i == 18) return 0x06633a6d46c11662e3f69fcd309b73cc20bd47a870d778c20e661915874c2d30;
        else if (i == 19) return 0x01a45cc8ac3691a5cab011322c3768c87051c572235a0cca492dff6909612077;
        else if (i == 20) return 0x279add35717f68d654619ffb44243d67f2e1085ae096b87da5f4e03b12c0198f;
        else if (i == 21) return 0x14abf2e9cc1540de67faffd47b74b2ff21db44fd5909c2c6dc0a7910183672d1;
        else if (i == 22) return 0x014d77e356b2fc343bad244a2c7b82793b1d407624237045b8cdb73e58be4804;
        else if (i == 23) return 0x10e949fa93056d968937b8b3990db726a22596ea35238a41af824cfa44d79309;
        else if (i == 24) return 0x19c69248dcc169fb60a3dc50f25cbcfeff75f9876e76a76c7cc3356eee4746ba;
        else if (i == 25) return 0x126f559140de04a5b3074e0ecbb46c942fbf0fc1118e4cab0e509ec7942acdf4;
        else if (i == 26) return 0x015a03f1243d220d72e914a76f815a66d0fae19bf83f7ed126124bb718b45638;
        else if (i == 27) return 0x0d234d5a13d6451120bf427a97a64a01b86122bc7056c9db235b4708d6257fd9;
        else if (i == 28) return 0x258f2eb745d4c7f43f7555fcd719408e4d484ed8ed1cf0a367410f24df079be0;
        else if (i == 29) return 0x2a7a8cb5c71e208c985ef3da812d40201012fdb07883372822b0a5c8c5e46a6d;
        else if (i == 30) return 0x02dfa7a6426b9c6700075ef9d9a2a964f9e54e5643c78b14a6fddcff44e81e41;
        else if (i == 31) return 0x136e847efd90cf461eac4b58b7f0fde18cf8564730c0b56ee7919be0816679a5;
        else revert("Index out of bounds");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Pairing {

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
        require(success, "pairing-add-failed");
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
        require(success, "pairing-mul-failed");
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length, "pairing-lengths-failed");
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
        require(success, "pairing-opcode-failed");
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

contract DepositVerifier {
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
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );
        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
            6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
            10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
            10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
            8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [12935167404754907266920816903692552965158971976791817284834979656884512282769,
            16702863240452200223508505813831232045929695112956360003894274945299691835395],
            [6278833835263542663346633729912974396079084603431842475317459082655651310024,
            20010334230181477404788003092375262349920977855843241949759734523400884200041]
        );
        vk.IC = new Pairing.G1Point[](6);
        
        vk.IC[0] = Pairing.G1Point(
            6441404960462403477367753357311312874931691560482462129582579226309621516235,
            885741994000836247721982674217050238006398676449598539471570740884291547072
        );
        
        vk.IC[1] = Pairing.G1Point(
            4070851264904830177326747979606101029712995456228308301075717509578060612338,
            4701393098435393217703543507218700233934152428232344671846070134817788949615
        );
        
        vk.IC[2] = Pairing.G1Point(
            7080047572781771403706047029538827679974230385195480857120108843082507121407,
            6534292803404640284842454174465974385492330395044063981414970489440266675776
        );
        
        vk.IC[3] = Pairing.G1Point(
            5868175497226398071822045697610074144684211068868703240150151977034981498227,
            6467903105092507032089133830181189128653262984275870342290809148322402201018
        );
        
        vk.IC[4] = Pairing.G1Point(
            10016262546292873561046851868520159183854645427177518548941598257670890824145,
            19618012860124140161923720843023435823898248268496272949241435520082038466464
        );
        
        vk.IC[5] = Pairing.G1Point(
            1953876692955304585342966204611026299975217230088875326809186621450789882761,
            20223850671325123310616330440236127552877241981500614241853469249728433308237
        );
        
    }

    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[5] memory input
    ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for (uint i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}