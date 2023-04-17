// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "./console.sol";
import "./Token.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Counters.sol";

contract Main is Ownable, EIP712 {
    using Counters for Counters.Counter;
    uint public fee = 25; // 0.25% -> 1 == 1/10.000
    Token public immutable token;
    address public gameMaster;

    mapping(address => Counters.Counter) private _nonces;

    /**
     * @notice PermitTransfer it is necessary that the game master
     * does not have the opportunity to write off funds from the user without his consent
     */
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "PermitTransfer(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    modifier onlyGameMaster() {
        require(msg.sender == gameMaster, "No allowance");
        _;
    }

    constructor(Token _token) EIP712("PermitTransfer", "1") {
        token = _token;
        gameMaster = msg.sender;
    }

    // constructor() EIP712("PermitTransfer", "1") {
    //     token = Token(msg.sender);
    //     gameMaster = msg.sender;
    // }

    function transferTokens(
        address[] memory users,
        uint amount,
        uint deadline,
        bytes[] memory signatures
    ) external onlyGameMaster {
        require(
            signatures.length == users.length,
            "Number of signatures does not match number of users"
        );

        for (uint i = 0; i < users.length; ++i) {
            bytes memory signature = signatures[i];
            require(signature.length == 65, "Invalid signature length");

            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 32))
                s := mload(add(signature, 64))
                v := byte(0, mload(add(signature, 96)))
            }

            require(
                permitTransfer(users[i], address(this), amount, deadline, v, r, s),
                "Invalid signature"
            );
        }
        // require(token._sudoTranfer(users, amount), "Something went wrong");
    }

    function awardTheWinner(address winner, uint amount) external onlyGameMaster {
        uint finalAmount = (amount * (10000 - fee)) / (10000);
        require(token._awardWinner(winner, finalAmount), "Something went wrong");
    }

    function setGameMaster(address _newGameMaster) external onlyOwner {
        require(_newGameMaster != address(0), "Zero address");
        gameMaster = _newGameMaster;
    }

    // CHANGE TO INTERNAL
    function permitTransfer(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private returns (bool) {
        require(block.timestamp <= deadline, "PermitTransfer: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "PermitTransfer: invalid signature");
        return true;
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    // GameMaster = deployer
    // NOTE potentially frontrun
    // NOTE potentially DOS   ?? Maybe with mapping(address -> is allowed???) possibleTransfer
    // extra tokens
    // 5/5   4/5     (100 * 97 / 100) + 500
    // transfer off mapping(address -> bool) allowed??
    // func witdraw burned?
    // leave => 1/20
    // 1 in month
    // noob 50 + 100  1/10   // MM
    // pro 300 + 1000 1/20   // WE
    // MAX matches per month ~ 200?300?   GasPrice/10*300 = sub
    // Coef * 10
    // patrol?
}