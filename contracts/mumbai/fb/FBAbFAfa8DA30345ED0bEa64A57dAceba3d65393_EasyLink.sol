// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./MerkleTree.sol";
import "./Verifier.sol";

contract EasyLink is MerkleTree {

    address public immutable token;
    uint256 public immutable amount;

    address public immutable verifier;

    mapping(uint256 => bool) public commitments;
    mapping(uint256 => bool) public spentNullifiers;

    event Deposit(bytes32 recipient, bytes encryptedNote, uint256 commitment, uint32 index);

    constructor(
        address _token,
        uint256 _amount,
        address _verifier,
        uint8 _levels,
        address _hasher
    ) MerkleTree(_levels, _hasher) {
        token = _token;
        amount = _amount;
        verifier = _verifier;
    }

    function deposit(bytes32 recipient, bytes calldata encryptedNote, uint256 commitment) external {
        require(!commitments[commitment], "Duplicated commitment");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint32 index = insert(commitment);
        commitments[commitment] = true;

        emit Deposit(recipient, encryptedNote, commitment, index);
    }

    function withdraw(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256 nullifierHash,
        address recipient,
        uint256 merkleRoot
    ) external {
        require(!spentNullifiers[nullifierHash], "Nullifier already spent");
        require(isValidRoot(merkleRoot), "Root is not valid");
        require(Verifier(verifier).verifyProof(a, b, c, [nullifierHash, uint256(uint160(recipient)), merkleRoot]), "Proof is not valid");

        spentNullifiers[nullifierHash] = true;

        IERC20(token).transfer(recipient, amount);
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
        require(_levels <= 10, "_levels should not be greater than 10");
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

    // poseidon(keccak256("easy-links") % FIELD_SIZE)
    function zeros(uint256 i) public pure returns (uint256) {
        if (i == 0) return 0x1b47eebd31a8cdbc109d42a60ae2f77d3916fdf63e1d6d3c9614c84c66587616;
        else if (i == 1) return 0x0998c45a8df60690d2142a1e29541e4c5203c5f0039e1f736a48a4ea3939996c;
        else if (i == 2) return 0x1b8525aeb12de720fbc32b7a5b505efc1bd4396e223644aed9d48c4ecc5a6451;
        else if (i == 3) return 0x1937e198ced295751ebf9996ad4429473bb657521a76f372ab62eab9dd09f729;
        else if (i == 4) return 0x043fae75b0a1c6cfe6bbd4a260fc421f26cd352974d31d3627896a677f3931a3;
        else if (i == 5) return 0x7c68bad132df37627c5fa5e1c06601d5af97124b0bd19f6e29593e1814ae51;
        else if (i == 6) return 0x2aca3ddb1f0c22cd53383b85231c1a10634f160ce945c639b2b799ed8b37f5ae;
        else if (i == 7) return 0x037ca32d66c15af3f7cb3cbc7d5b0fad9104582d24416fdd85c50586d3079a0e;
        else if (i == 8) return 0x1c9e22b869e38db54e772baa9a4765b9ccb1ea458ea4a50c3ce9ce5152a95581;
        else if (i == 9) return 0x283f3963c14e4a1873557637cf74773b5de1d3dcafa8c2c82f18720fabd5e0f9;
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
            [14017294471845467262020098929288901640946069877481331712872323249082187988730,
            12135345851815756866960980393077818777031454550717173374788491441254982816381],
            [15088560101748724120930750495920785963030967913867292653681577381382118126356,
            10877843538500632492885553978893601128763218793812812839342484816108963128109]
        );
        vk.IC = new Pairing.G1Point[](4);
        
        vk.IC[0] = Pairing.G1Point(
            12440243382614964294183084030049955173832225260123986697504015332940305420258,
            9390298533993462964188730309989866186432660261525201342011288498840573898963
        );
        
        vk.IC[1] = Pairing.G1Point(
            4425815958065361522711035223857887540768745722527432088514394249634256058130,
            11499097358439870138287439420068228020677777311612492148923083783790385099745
        );
        
        vk.IC[2] = Pairing.G1Point(
            18941488472540675676053045959760710236846963278668482199411944716384935946177,
            2861228874774203673756632129910443901511997936552617230289499204008224660681
        );
        
        vk.IC[3] = Pairing.G1Point(
            21710117620626066906473054731152826505758197317592154285833275563987402093684,
            12531069195304368357475031680574507611051579185034285557432978515483349759994
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
        uint[3] memory input
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