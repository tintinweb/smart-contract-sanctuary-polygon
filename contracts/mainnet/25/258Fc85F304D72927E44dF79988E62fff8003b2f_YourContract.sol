/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract YourContract {
    /* CONSTANTS */
    uint256 P =
        0xE96C6372AB55884E99242C8341393C43953A3C8C6F6D57B3B863C882DEFFC3B7;
    uint256 Q =
        0x74B631B955AAC4274C921641A09C9E21CA9D1E4637B6ABD9DC31E4416F7FE1DB;

    uint256 last_id = 0;

    address payable owner = payable(0xB986AE15b82d88b81A10E9E2B7fa13A7b9254fF4);

    /* MODIFIERS */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isState(uint256 id, State s) {
        require(processes[id].state == s);
        _;
    }

    modifier isOwned(uint256 id) {
        require(
            msg.sender == processes[id].alice || msg.sender == processes[id].bob
        );
        _;
    }

    modifier valid(uint256 id) {
        require(!processes[id].bob_cheating && !processes[id].alice_cheating);
        _;
    }

    /* MATH */
    function mod_exp(
        uint256 _b,
        uint256 _e,
        uint256 _m
    ) internal returns (uint256 result) {
        assembly {
            // Free memory pointer
            let pointer := mload(0x40)

            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)

            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), _b)
            mstore(add(pointer, 0x80), _e)
            mstore(add(pointer, 0xa0), _m)

            // Store the result
            let value := mload(0xc0)

            // Call the precompiled contract 0x05 = bigModExp
            if iszero(call(not(0), 0x05, 0, pointer, 0xc0, value, 0x20)) {
                revert(0, 0)
            }

            result := mload(value)
        }
    }

    function make_commitment(uint256 id, Ciphertext calldata e)
        internal
        returns (uint256 c)
    {
        uint256 g1 = mod_exp(processes[id].G, e.a, P);
        uint256 g2 = mod_exp(processes[id].G, e.b, P);

        c = mulmod(g1, g2, P);
    }

    function verify_commitment(
        uint256 id,
        Ciphertext calldata e,
        uint256 c
    ) internal returns (bool is_valid) {
        uint256 c_result = make_commitment(id, e);

        return c_result == c;
    }

    function elgamal_encrypt(
        uint256 m,
        uint256 r,
        uint256 pk,
        uint256 id
    ) internal returns (Ciphertext memory e) {
        e.a = mod_exp(processes[id].G, r, P);
        e.b = mulmod(mod_exp(pk, r, P), m, P);
    }

    /* EVENTS */
    event Initiated(address indexed _from,  address indexed _to, uint256 indexed _id, uint256 _d, uint256 _z, uint256 _g, uint256 _y);
    event Commited(uint256 indexed _id, address indexed _from, uint256 _c);
    event Encrypted(uint256 indexed _id, address indexed _from, uint256 _a, uint256 _b);
    event Revealed(uint256 indexed _id, address indexed _from, uint256 _seed, uint256 _coeff);
    event Result(uint256 indexed _id, uint256 result);

    /* STATE */
    mapping(uint256 => ProcessData) processes;

    enum State {
        Free,
        WaitingOnCommitments,
        WaitingOnEncryptions,
        WaitingOnReveal,
        Finished
    }

    struct Reveal {
        uint256 seed;
        uint256 coeff;
    }

    struct Ciphertext {
        uint256 a;
        uint256 b;
    }

    struct ProcessData {
        uint256 id;
        State state;
        address alice;
        address bob;
        uint256 D;
        uint256 Z;
        uint256 G;
        uint256 Y;
        uint256 commitment_alice;
        uint256 commitment_bob;
        Ciphertext encryption_alice;
        Ciphertext encryption_bob;
        Reveal reveal_alice;
        Reveal reveal_bob;
        bool alice_done;
        bool bob_done;
        bool bob_cheating;
        bool alice_cheating;
    }

    function ClearProc(uint256 id, bool isBobCheating) internal {
        if (isBobCheating) {
            processes[id].bob_cheating = true;
        } else {
            processes[id].alice_cheating = true;
        }
    }

    function Initiate(
        address other,
        uint256 D,
        uint256 Z
    )
        public
        payable
    {
        require(D != 0, "D cannot be zero");
        require(D > Z, "D must be bigger than Z");

        uint256 id = last_id++;
        processes[id].alice = msg.sender;
        processes[id].bob = other;
        processes[id].Z = Z;
        processes[id].D = D;
        processes[id].Y = uint256(blockhash(block.number - 1));
        processes[id].G = mod_exp(processes[id].Y, 2, P);
        processes[id].state = State.WaitingOnCommitments;

        emit Initiated(msg.sender, other, id, D, Z, processes[id].G, processes[id].Y);
    }

    function AcceptCommitment(uint256 id, uint256 commitment)
        public
        isState(id, State.WaitingOnCommitments)
        isOwned(id)
        valid(id)
    {
        if (msg.sender == processes[id].alice) {
            require(
                processes[id].commitment_alice == 0,
                "Process already has commitment for this address"
            );
            processes[id].commitment_alice = commitment;
        } else if (msg.sender == processes[id].bob) {
            require(
                processes[id].commitment_bob == 0,
                "Process already has commitment for this address"
            );
            processes[id].commitment_bob = commitment;
        }
        GotAllCommitmentsQ(id);
        emit Commited(id, msg.sender, commitment);
    }

    function GotAllCommitmentsQ(uint256 id) internal {
        if (
            processes[id].commitment_alice != 0 &&
            processes[id].commitment_bob != 0
        ) {
            processes[id].state = State.WaitingOnEncryptions;
        }
    }

    function AcceptEncryption(uint256 id, Ciphertext calldata e)
        public
        isState(id, State.WaitingOnEncryptions)
        isOwned(id)
        valid(last_id)
    {
        if (msg.sender == processes[id].alice) {
            if (!verify_commitment(id, e, processes[id].commitment_alice)) {
                ClearProc(id, false);
                revert("Commitment was a lie. Process terminated.");
            }
            processes[id].encryption_alice = e;
        } else if (msg.sender == processes[id].bob) {
            if (!verify_commitment(id, e, processes[id].commitment_bob)) {
                ClearProc(id, true);
                revert("Commitment was a lie. Process terminated.");
            }
            processes[id].encryption_bob = e;
        }
        GotAllEncryptionsQ(id);
        emit Encrypted(id, msg.sender, e.a, e.b);
    }

    function GotAllEncryptionsQ(uint256 id) internal {
        if (
            processes[id].encryption_alice.a != 0 &&
            processes[id].encryption_alice.b != 0 &&
            processes[id].encryption_bob.a != 0 &&
            processes[id].encryption_bob.b != 0
        ) {
            processes[id].state = State.WaitingOnReveal;
        }
    }

    function AcceptReveal(uint256 id, Reveal calldata r)
        public
        isState(id, State.WaitingOnReveal)
        isOwned(id)
        valid(id)
    {
        if (msg.sender == processes[id].alice) {
            Ciphertext memory correct_alice = elgamal_encrypt(
                r.seed,
                r.coeff,
                processes[id].Y,
                id
            );

            if (
                correct_alice.a != processes[id].encryption_alice.a ||
                correct_alice.b != processes[id].encryption_alice.b
            ) {
                ClearProc(id, false);
                revert("Encryption was a lie. Process terminated.");
            }

            if (!(r.seed >= processes[id].Z && r.seed < processes[id].D)) {
                ClearProc(id, false);
                revert("Seed is not between Z and D. Process terminated.");
            }

            processes[id].reveal_alice = r;
            processes[id].alice_done = true;
        } else if (msg.sender == processes[id].bob) {
            Ciphertext memory correct_bob = elgamal_encrypt(
                r.seed,
                r.coeff,
                processes[id].Y,
                id
            );

            if (
                correct_bob.a != processes[id].encryption_bob.a ||
                correct_bob.b != processes[id].encryption_bob.b
            ) {
                ClearProc(id, true);
                revert("Encryption was a lie. Process terminated.");
            }

            if (r.seed > processes[id].D || r.seed < processes[id].Z) {
                ClearProc(id, true);
                revert("Seed is not between Z and D. Process terminated.");
            }

            processes[id].reveal_bob = r;
            processes[id].bob_done = true;
        }
        GotAllRevealsQ(id);
        emit Revealed(id, msg.sender, r.seed, r.coeff);
    }

    function GotAllRevealsQ(uint256 id) internal {
        if (processes[id].alice_done && processes[id].bob_done) {
            processes[id].state = State.Finished;
                    emit Result(id, ((processes[id].reveal_alice.seed + processes[id].reveal_bob.seed) % (processes[id].D - processes[id].Z)) + processes[id].Z);

        }
    }

    function withdrawal(uint256 value) public onlyOwner {
        (bool sent, bytes memory data) = owner.call{value: value}("");
        require(sent);
    }

    receive() external payable {}

    fallback() external payable {}
}