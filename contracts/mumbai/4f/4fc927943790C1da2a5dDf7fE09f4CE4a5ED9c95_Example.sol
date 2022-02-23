pragma solidity ^0.8.4;

// import "./test/utils/console.sol";

contract Example {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Person {
        string name;
        address wallet;
    }

    struct Mail {
        Person from;
        Person to;
        string contents;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH =
    keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant PERSON_TYPEHASH =
    keccak256("Person(string name,address wallet)");

    bytes32 constant MAIL_TYPEHASH =
    keccak256(
        "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
    );

    bytes32 DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
            name: "Foo exchange",
            version: "1",
            chainId: block.chainid,
            verifyingContract: address(this)
            })
        );
    }

    function getChainId() public view returns (uint){

        return block.chainid;
    }

    function hash(EIP712Domain memory eip712Domain)
    public
    pure
    returns (bytes32)
    {
        return
        keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            )
        );
    }

    function hash(Person memory person) public pure returns (bytes32) {
        return
        keccak256(
            abi.encode(
                PERSON_TYPEHASH,
                keccak256(bytes(person.name)),
                person.wallet
            )
        );
    }

    function hash(Mail memory mail) public pure returns (bytes32) {
        return
        keccak256(
            abi.encode(
                MAIL_TYPEHASH,
                hash(mail.from),
                hash(mail.to),
                keccak256(bytes(mail.contents))
            )
        );
    }


    function testVerify(
        string memory nameA,
        address walletA,
        string memory nameB,
        address walletB,
        string memory contents,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {

        Person memory from = Person(nameA,walletA);
        Person memory to = Person(nameB,walletB);
        Mail memory mail = Mail(from,to,contents);

        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(mail))
        );
        return ecrecover(digest, v, r, s) == mail.from.wallet;
    }

    function verify(
        Mail memory mail,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(mail))
        );
        return ecrecover(digest, v, r, s) == mail.from.wallet;
    }
}