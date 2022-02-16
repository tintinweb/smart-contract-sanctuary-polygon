/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract SnarkConstants {
    // The scalar field
    uint256 internal constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
}

library PoseidonT3 {
    function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}

// library PoseidonT4 {
//     function poseidon(uint256[3] memory input) public pure returns (uint256) {}
// }

// library PoseidonT5 {
//     function poseidon(uint256[4] memory input) public pure returns (uint256) {}
// }

library PoseidonT6 {
    function poseidon(uint256[5] memory input) public pure returns (uint256) {}
}

/*
 * A SHA256 hash function for any number of input elements, and Poseidon hash
 * functions for 2, 3, 4, 5, and 12 input elements.
 */
contract Hasher is SnarkConstants {
    function sha256Hash(uint256[] memory array) public pure returns (uint256) {
        return uint256(sha256(abi.encodePacked(array))) % SNARK_SCALAR_FIELD;
    }

    function hash2(uint256[2] memory array) public pure returns (uint256) {
        return PoseidonT3.poseidon(array);
    }

    // function hash3(uint256[3] memory array) public pure returns (uint256) {
    //     return PoseidonT4.poseidon(array);
    // }

    // function hash4(uint256[4] memory array) public pure returns (uint256) {
    //     return PoseidonT5.poseidon(array);
    // }

    function hash5(uint256[5] memory array) public pure returns (uint256) {
        return PoseidonT6.poseidon(array);
    }

    function hashLeftRight(uint256 _left, uint256 _right)
    public
    pure
    returns (uint256)
    {
        uint256[2] memory input;
        input[0] = _left;
        input[1] = _right;
        return hash2(input);
    }
}

contract IPubKey {
    struct PubKey {
        uint256 x;
        uint256 y;
    }
}

contract IMessage {
    uint8 constant MESSAGE_DATA_LENGTH = 7;

    struct Message {
        uint256[MESSAGE_DATA_LENGTH] data;
    }
}

contract DomainObjs is IMessage, Hasher, IPubKey {
    struct StateLeaf {
        PubKey pubKey;
        uint256 voiceCreditBalance;
        uint256 voteOptionTreeRoot;
        uint256 nonce;
    }

    function hashStateLeaf(StateLeaf memory _stateLeaf) public pure returns (uint256) {
        uint256[5] memory plaintext;
        plaintext[0] = _stateLeaf.pubKey.x;
        plaintext[1] = _stateLeaf.pubKey.y;
        plaintext[2] = _stateLeaf.voiceCreditBalance;
        plaintext[3] = _stateLeaf.voteOptionTreeRoot;
        plaintext[4] = _stateLeaf.nonce;

        return hash5(plaintext);
    }
}

contract Ownable {
  address public admin;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    admin = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newAdmin The address to transfer ownership to.
   */
  function transferOwnership(address newAdmin) external onlyOwner {
    require(newAdmin != address(0));
    emit OwnershipTransferred(admin, newAdmin);
    admin = newAdmin;
  }
}

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] x;
        uint256[2] y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero. 
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.x == 0 && p.y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.x;
        input[1] = p1.y;
        input[2] = p2.x;
        input[3] = p2.y;
        bool success;

        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        bool success;

        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
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

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];

        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].x;
            input[j + 1] = p1[i].y;
            input[j + 2] = p2[i].x[0];
            input[j + 3] = p2[i].x[1];
            input[j + 4] = p2[i].y[0];
            input[j + 5] = p2[i].y[1];
        }

        uint256[1] memory out;
        bool success;

        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-opcode-failed");

        return out[0] != 0;
    }
}


contract SnarkCommon {
    struct VerifyingKey {
        Pairing.G1Point alpha1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] ic;
    }
}

/*
 * Stores verifying keys for the circuits.
 * Each circuit has a signature which is its compile-time constants represented
 * as a uint256.
 */
contract VkRegistry is Ownable, SnarkCommon {

    mapping (uint256 => VerifyingKey) internal processVks; 
    mapping (uint256 => bool) internal processVkSet; 

    mapping (uint256 => VerifyingKey) internal tallyVks; 
    mapping (uint256 => bool) internal tallyVkSet; 

    //TODO: event for setVerifyingKeys

    function isProcessVkSet(uint256 _sig) public view returns (bool) {
        return processVkSet[_sig];
    }

    function isTallyVkSet(uint256 _sig) public view returns (bool) {
        return tallyVkSet[_sig];
    }

    function genProcessVkSig(
        uint256 _stateTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize
    ) public pure returns (uint256) {
        return 
            (_messageBatchSize << 192) +
            (_stateTreeDepth << 128) +
            _voteOptionTreeDepth;
    }

    function genTallyVkSig(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public pure returns (uint256) {
        return 
            (_stateTreeDepth << 128) +
            (_intStateTreeDepth << 64) +
            _voteOptionTreeDepth;
    }

    function setVerifyingKeys(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _messageBatchSize,
        uint256 _voteOptionTreeDepth,
        VerifyingKey memory _processVk,
        VerifyingKey memory _tallyVk
    ) public onlyOwner {

        uint256 processVkSig = genProcessVkSig(
            _stateTreeDepth,
            _voteOptionTreeDepth,
            _messageBatchSize
        );

        // * DEV *
        // require(processVkSet[processVkSig] == false, "VkRegistry: process vk already set");

        uint256 tallyVkSig = genTallyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        // * DEV *
        // require(tallyVkSet[tallyVkSig] == false, "VkRegistry: tally vk already set");

        VerifyingKey storage processVk = processVks[processVkSig];
        processVk.alpha1 = _processVk.alpha1;
        processVk.beta2 = _processVk.beta2;
        processVk.gamma2 = _processVk.gamma2;
        processVk.delta2 = _processVk.delta2;
        // * DEV *
        delete processVk.ic;
        for (uint8 i = 0; i < _processVk.ic.length; i ++) {
            processVk.ic.push(_processVk.ic[i]);
        }

        processVkSet[processVkSig] = true;

        VerifyingKey storage tallyVk = tallyVks[tallyVkSig];
        tallyVk.alpha1 = _tallyVk.alpha1;
        tallyVk.beta2 = _tallyVk.beta2;
        tallyVk.gamma2 = _tallyVk.gamma2;
        tallyVk.delta2 = _tallyVk.delta2;
        // * DEV *
        delete tallyVk.ic;
        for (uint8 i = 0; i < _tallyVk.ic.length; i ++) {
            tallyVk.ic.push(_tallyVk.ic[i]);
        }
        tallyVkSet[tallyVkSig] = true;
    }

    function hasProcessVk(
        uint256 _stateTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize
    ) public view returns (bool) {
        uint256 sig = genProcessVkSig(
            _stateTreeDepth,
            _voteOptionTreeDepth,
            _messageBatchSize
        );
        return processVkSet[sig];
    }

    function getProcessVkBySig(
        uint256 _sig
    ) public view returns (VerifyingKey memory) {
        require(processVkSet[_sig] == true, "VkRegistry: process verifying key not set");

        return processVks[_sig];
    }

    function getProcessVk(
        uint256 _stateTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize
    ) public view returns (VerifyingKey memory) {
        uint256 sig = genProcessVkSig(
            _stateTreeDepth,
            _voteOptionTreeDepth,
            _messageBatchSize
        );

        return getProcessVkBySig(sig);
    }

    function hasTallyVk(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public view returns (bool) {
        uint256 sig = genTallyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        return tallyVkSet[sig];
    }

    function getTallyVkBySig(
        uint256 _sig
    ) public view returns (VerifyingKey memory) {
        require(tallyVkSet[_sig] == true, "VkRegistry: tally verifying key not set");

        return tallyVks[_sig];
    }

    function getTallyVk(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public view returns (VerifyingKey memory) {
        uint256 sig = genTallyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        return getTallyVkBySig(sig);
    }
}

abstract contract IVerifier is SnarkCommon {
    function verify(
        uint256[8] memory,
        VerifyingKey memory,
        uint256
    ) virtual public view returns (bool);
}

contract MockVerifier is IVerifier, SnarkConstants {
    bool result = true;
    function verify(
        uint256[8] memory,
        VerifyingKey memory,
        uint256
    ) override public view returns (bool) {
        return result;
    }
}

contract Verifier is IVerifier, SnarkConstants {
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }

    using Pairing for *;

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    string constant ERROR_PROOF_Q = "VE1";
    string constant ERROR_INPUT_VAL = "VE2";

    /*
     * @returns Whether the proof is valid given the verifying key and public
     *          input. Note that this function only supports one public input.
     *          Refer to the Semaphore source code for a verifier that supports
     *          multiple public inputs.
     */
    function verify(
        uint256[8] memory _proof,
        VerifyingKey memory vk,
        uint256 input
    ) override public view returns (bool) {
        Proof memory proof;
        proof.a = Pairing.G1Point(_proof[0], _proof[1]);
        proof.b = Pairing.G2Point(
            [_proof[2], _proof[3]],
            [_proof[4], _proof[5]]
        );
        proof.c = Pairing.G1Point(_proof[6], _proof[7]);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.a.x < PRIME_Q, ERROR_PROOF_Q);
        require(proof.a.y < PRIME_Q, ERROR_PROOF_Q);

        require(proof.b.x[0] < PRIME_Q, ERROR_PROOF_Q);
        require(proof.b.y[0] < PRIME_Q, ERROR_PROOF_Q);

        require(proof.b.x[1] < PRIME_Q, ERROR_PROOF_Q);
        require(proof.b.y[1] < PRIME_Q, ERROR_PROOF_Q);

        require(proof.c.x < PRIME_Q, ERROR_PROOF_Q);
        require(proof.c.y < PRIME_Q, ERROR_PROOF_Q);

        // Make sure that the input is less than the snark scalar field
        require(input < SNARK_SCALAR_FIELD, ERROR_INPUT_VAL);

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        vk_x = Pairing.plus(
            vk_x,
            Pairing.scalar_mul(vk.ic[1], input)
        );

        vk_x = Pairing.plus(vk_x, vk.ic[0]);

        return Pairing.pairing(
            Pairing.negate(proof.a),
            proof.b,
            vk.alpha1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.c,
            vk.delta2
        );
    }
}

interface SignUpGatekeeper {
    function setMaciInstance(address _maci) external;
    function register(address _user, bytes memory _data) external returns (bool, uint256);
}

abstract contract MerkleZeros {
    uint256[9] internal zeros;

    // Quinary tree zeros (0)
    constructor() {
        zeros[0] = uint256(0);
        zeros[1] = uint256(14655542659562014735865511769057053982292279840403315552050801315682099828156);
        zeros[2] = uint256(19261153649140605024552417994922546473530072875902678653210025980873274131905);
        zeros[3] = uint256(21526503558325068664033192388586640128492121680588893182274749683522508994597);
        zeros[4] = uint256(20017764101928005973906869479218555869286328459998999367935018992260318153770);
        zeros[5] = uint256(16998355316577652097112514691750893516081130026395813155204269482715045879598);
        zeros[6] = uint256(2612442706402737973181840577010736087708621987282725873936541279764292204086);
        zeros[7] = uint256(17716535433480122581515618850811568065658392066947958324371350481921422579201);
        zeros[8] = uint256(17437916409890180001398333108882255895598851862997171508841759030332444017770);
    }
}

contract QuinaryTreeRoot is MerkleZeros {
    uint256 public constant DEGREE = 5;

    function rootOf(uint256 _depth, uint256[] memory _nodes) public view returns (uint256) {
        uint256 capacity = DEGREE ** _depth;
        uint256 length = _nodes.length;

        require(capacity >= length, "overflow");

        uint256 c = capacity / DEGREE;
        uint256 pl = (length - 1) / DEGREE + 1;
        for (uint256 i = 0; i < _depth; i++) {
            uint256 zero = getZero(i);
            // number of non-zero parent nodes
            pl = (length - 1) / DEGREE + 1;
            for (uint256 j = 0; j < c; j ++) {
                if (j >= length) {
                    continue;
                }
                uint256 h = 0;
                if (j < pl) {
                    uint256[5] memory inputs;
                    uint256 s = 0;
                    for (uint256 k = 0; k < 5; k++) {
                        uint256 node = 0;
                        uint256 idx = j * 5 + k;
                        if (idx < length) {
                            node = _nodes[idx];
                        }
                        s += node;
                        if (node == 0) {
                            node = zero;
                        }
                        inputs[k] = node;
                    }
                    if (s > 0) {
                        h = PoseidonT6.poseidon(inputs);
                    }
                }
                _nodes[j] = h;
            }

            pl = (pl - 1) / DEGREE + 1;
            c = c / DEGREE;
        }

        return _nodes[0];
    }

    function getZero(uint256 _height) internal view returns (uint256) {
        return zeros[_height];
    }
}

contract MACI is DomainObjs, SnarkCommon, Ownable {
    struct MaciParameters {
        uint256 stateTreeDepth;
        uint256 intStateTreeDepth;
        uint256 messageBatchSize;
        uint256 voteOptionTreeDepth;
    }

    enum Period {
        Pending,
        Voting,
        Processing,
        Tallying,
        Ended
    }

    uint256 constant private STATE_TREE_ARITY = 5;

    uint256 public coordinatorHash;

    SignUpGatekeeper public gateKeeper;

    // The verifying key registry. There may be multiple verifying keys stored
    // on chain, and Poll contracts must select the correct VK based on the
    // circuit's compile-time parameters, such as tree depths and batch sizes.
    VkRegistry public vkRegistry;

    // Verify the results at the final counting stage.
    QuinaryTreeRoot public qtrLib;

    Verifier public verifier;

    MaciParameters public parameters;

    Period public period;

    mapping (address => uint256) public stateIdxInc;
    mapping (uint256 => uint256) public voiceCreditBalance;

    uint256 public numSignUps;
    uint256 public maxVoteOptions;

    uint256 public msgChainLength;
    mapping (uint256 => uint256) public msgHashes;
    uint256 public currentStateCommitment;
    uint256 private _processedMsgCount;

    uint256 public currentTallyCommitment;
    uint256 private _processedUserCount;

    mapping (uint256 => uint256) public result;

    uint256 private _maxLeavesCount;
    uint256 private _leafIdx0;
    uint256[8] private _zeros;
    /*
     *  length: (5 ** (depth + 1) - 1) / 4
     *
     *  hashes(leaves) at depth D: nodes[n]
     *  n => [ (5**D-1)/4 , (5**(D+1)-1)/4 )
     */
    mapping (uint256 => uint256) private _nodes;

    uint256 public totalResult;

    event SignUp(uint256 indexed _stateIdx, PubKey _userPubKey, uint256 _voiceCreditBalance);
    event PublishMessage(uint256 indexed _msgIdx, Message _message, PubKey _encPubKey);

    modifier atPeriod(Period _p) {
        require(_p == period, "MACI: period error");
        _;
    }
    
    function init(
        address _admin,
        VkRegistry _vkRegistry,
        QuinaryTreeRoot _qtrLib,
        Verifier _verifier,
        SignUpGatekeeper _gateKeeper,
        MaciParameters memory _parameters,
        PubKey memory _coordinator
    ) public atPeriod(Period.Pending) {
        admin = _admin;
        vkRegistry = _vkRegistry;
        qtrLib = _qtrLib;
        verifier = _verifier;
        gateKeeper = _gateKeeper;
        parameters = _parameters;
        coordinatorHash = hash2([_coordinator.x,  _coordinator.y]);

        // _stateTree.init();
        _maxLeavesCount = 5 ** _parameters.stateTreeDepth;
        _leafIdx0 = (_maxLeavesCount - 1) / 4;
        
        _zeros[0] = uint256(14655542659562014735865511769057053982292279840403315552050801315682099828156);
        _zeros[1] = uint256(19261153649140605024552417994922546473530072875902678653210025980873274131905);
        _zeros[2] = uint256(21526503558325068664033192388586640128492121680588893182274749683522508994597);
        _zeros[3] = uint256(20017764101928005973906869479218555869286328459998999367935018992260318153770);
        _zeros[4] = uint256(16998355316577652097112514691750893516081130026395813155204269482715045879598);
        _zeros[5] = uint256(2612442706402737973181840577010736087708621987282725873936541279764292204086);
        _zeros[6] = uint256(17716535433480122581515618850811568065658392066947958324371350481921422579201);
        _zeros[7] = uint256(17437916409890180001398333108882255895598851862997171508841759030332444017770);

        period = Period.Voting;
    }

    function hashMessageAndEncPubKey(
        Message memory _message,
        PubKey memory _encPubKey,
        uint256 _prevHash
    ) public pure returns (uint256) {
        uint256[5] memory m;
        m[0] = _message.data[0];
        m[1] = _message.data[1];
        m[2] = _message.data[2];
        m[3] = _message.data[3];
        m[4] = _message.data[4];

        uint256[5] memory n;
        n[0] = _message.data[5];
        n[1] = _message.data[6];
        n[2] = _encPubKey.x;
        n[3] = _encPubKey.y;
        n[4] = _prevHash;

        return hash2([hash5(m), hash5(n)]);
    }

    function stateOf(address _signer) public view returns (uint256, uint256) {
        uint256 ii = stateIdxInc[_signer];
        require(ii >= 1);
        uint256 stateIdx = ii - 1;
        uint256 balance = voiceCreditBalance[stateIdx];
        return (stateIdx, balance);
    }

    function signUp(
        PubKey memory _pubKey,
        bytes memory _data
    ) public atPeriod(Period.Voting) {
        require(numSignUps < _maxLeavesCount, "full");
        require(
            _pubKey.x < SNARK_SCALAR_FIELD && _pubKey.y < SNARK_SCALAR_FIELD,
            "MACI: _pubKey values should be less than the snark scalar field"
        );

        (bool valid, uint256 balance) = gateKeeper.register(msg.sender, _data);

        require(valid, "401");

        uint256 stateLeaf = hashStateLeaf(
            StateLeaf(_pubKey, balance, 0, 0)
        );
        uint256 stateIndex = numSignUps;
        _stateEnqueue(stateLeaf);
        numSignUps++;

        stateIdxInc[msg.sender] = numSignUps;
        voiceCreditBalance[stateIndex] = balance;

        emit SignUp(stateIndex, _pubKey, balance);
    }

    function publishMessage(
        Message memory _message,
        PubKey memory _encPubKey
    ) public atPeriod(Period.Voting) {
        require(
            _encPubKey.x != 0 &&
            _encPubKey.y != 1 &&
            _encPubKey.x < SNARK_SCALAR_FIELD &&
            _encPubKey.y < SNARK_SCALAR_FIELD,
            "MACI: invalid _encPubKey"
        );

        msgHashes[msgChainLength + 1] = hashMessageAndEncPubKey(
            _message,
            _encPubKey,
            msgHashes[msgChainLength]
        );

        emit PublishMessage(msgChainLength, _message, _encPubKey);
        msgChainLength++;
    }

    function batchPublishMessage(
        Message[] memory _messages,
        PubKey[] memory _encPubKeys
    ) public {
        require(_messages.length == _encPubKeys.length);
        for (uint256 i = 0; i < _messages.length; i++) {
            publishMessage(_messages[i], _encPubKeys[i]);
        }
    }

    function stopVotingPeriod(uint256 _maxVoteOptions) public onlyOwner atPeriod(Period.Voting) {
        maxVoteOptions = _maxVoteOptions;
        period = Period.Processing;

        currentStateCommitment = hash2([_stateRoot() , 0]);
    }

    // Transfer state root according to message queue.
    function processMessage(
        uint256 newStateCommitment,
        uint256[8] memory _proof
    ) public atPeriod(Period.Processing) {
        require(_processedMsgCount < msgChainLength, "all messages have been processed");

        uint256 batchSize = parameters.messageBatchSize;

        uint256[] memory input = new uint256[](6);
        input[0] = (numSignUps << uint256(32)) + maxVoteOptions;    // packedVals
        input[1] = coordinatorHash;                                 // coordPubKeyHash

        uint256 batchStartIndex = (msgChainLength - _processedMsgCount - 1) / batchSize * batchSize;
        uint256 batchEndIdx = batchStartIndex + batchSize;
        if (batchEndIdx > msgChainLength) {
            batchEndIdx = msgChainLength;
        }
        input[2] = msgHashes[batchStartIndex];                      // batchStartHash
        input[3] = msgHashes[batchEndIdx];                          // batchEndHash

        input[4] = currentStateCommitment;
        input[5] = newStateCommitment;

        uint256 inputHash = uint256(sha256(abi.encodePacked(input))) % SNARK_SCALAR_FIELD;

        VerifyingKey memory vk = vkRegistry.getProcessVk(
            parameters.stateTreeDepth,
            parameters.voteOptionTreeDepth,
            batchSize
        );

        bool isValid = verifier.verify(_proof, vk, inputHash);
        require(isValid, "invalid proof");

        // Proof success, update commitment and progress.
        currentStateCommitment = newStateCommitment;
        _processedMsgCount += batchEndIdx - batchStartIndex;
    }

    function stopProcessingPeriod() public atPeriod(Period.Processing) {
        require(_processedMsgCount == msgChainLength);
        period = Period.Tallying;

        // unnecessary writes
        // currentTallyCommitment = 0;
    }

    function processTally(
        uint256 newTallyCommitment,
        uint256[8] memory _proof
    ) public atPeriod(Period.Tallying) {
        require(_processedUserCount < numSignUps, "all users have been processed");
    
        uint256 batchSize = 5 ** parameters.intStateTreeDepth;
        uint256 batchNum = _processedUserCount / batchSize;

        uint256[] memory input = new uint256[](4);
        input[0] = (numSignUps << uint256(32)) + batchNum;          // packedVals

        // The state commitment will not change after
        // the end of the processing period.
        input[1] = currentStateCommitment;                          // stateCommitment
        input[2] = currentTallyCommitment;                          // tallyCommitment
        input[3] = newTallyCommitment;                              // newTallyCommitment

        uint256 inputHash = uint256(sha256(abi.encodePacked(input))) % SNARK_SCALAR_FIELD;

        VerifyingKey memory vk = vkRegistry.getTallyVk(
            parameters.stateTreeDepth,
            parameters.intStateTreeDepth,
            parameters.voteOptionTreeDepth
        );

        bool isValid = verifier.verify(_proof, vk, inputHash);
        require(isValid, "invalid proof");

        // Proof success, update commitment and progress.
        currentTallyCommitment = newTallyCommitment;
        _processedUserCount += batchSize;
    }

    function stopTallyingPeriod(uint256[] memory _results, uint256 _salt) public atPeriod(Period.Tallying) {
        require(_processedUserCount >= numSignUps);
        require(_results.length <= maxVoteOptions);

        uint256 resultsRoot = qtrLib.rootOf(parameters.voteOptionTreeDepth, _results);
        uint256 tallyCommitment = hash2([resultsRoot, _salt]);
        
        require(tallyCommitment == currentTallyCommitment);

        uint256 sum = 0;
        for (uint256 i = 0; i < _results.length; i++) {
            result[i] = _results[i];
            sum += _results[i];
        }
        totalResult = sum;

        period = Period.Ended;
    }

    function stopTallyingPeriodWithoutResults() public onlyOwner atPeriod(Period.Tallying) {
        require(_processedUserCount >= numSignUps);
        period = Period.Ended;
    }

    function _stateRoot() private view returns (uint256) {
        return _nodes[0];
    }

    function _stateEnqueue(uint256 _leaf) private {
        uint256 leafIdx = _leafIdx0 + numSignUps;
        _nodes[leafIdx] = _leaf;
        _stateUpdateAt(leafIdx);
    }

    function _stateUpdateAt(uint256 _index) private {
        require(_index >= _leafIdx0, "must update from height 0");

        uint256 idx = _index;
        uint256 height = 0;
        while (idx > 0) {
            uint256 parentIdx = (idx - 1) / 5;
            uint256 childrenIdx0 = parentIdx * 5 + 1;

            uint256 zero = _zeros[height];

            uint256[5] memory inputs;
            for (uint256 i = 0; i < 5; i++) {
                uint256 child = _nodes[childrenIdx0 + i];
                if (child == 0) {
                    child = zero;
                }
                inputs[i] = child;
            }
            _nodes[parentIdx] = hash5(inputs);

            height++;
            idx = parentIdx;
        }
    }
}