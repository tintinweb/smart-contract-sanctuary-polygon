/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
abstract contract StandardToken is IERC20 {
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   * @return balance representing the amount owned by the passed address.
   */
  function balanceOf(address _owner) public view override returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    balances[_from] = balances[_from] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(_from, _to, _value);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function _transferFrom(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    uint256 _allowance = allowed[_from][msg.sender];
    allowed[_from][msg.sender] = _allowance - _value;
    _transfer(_from, _to, _value);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public override returns (bool) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return remaining uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

// File: contracts/registrable.sol


pragma solidity >=0.8.0 <0.9.0;

interface IRegistry {
    function claim(address asset, uint256 amount) external returns (bool);  
    function burn(address user, uint256 amount) external returns (bool); 
}

abstract contract Registrable {
    address public registry;

    modifier onlyRegistry() {
        require(msg.sender == registry, "not registry");
        _;
    }

    constructor() {
        registry = msg.sender;
    }

    function evolve(address next) public onlyRegistry() {
        registry = next;
    }
}
// File: contracts/asset.sol


pragma solidity >=0.8.0 <0.9.0;



contract MixinAsset is Registrable, StandardToken {
    uint128 public immutable id;

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public constant decimals = 8;

    constructor(uint128 _id, string memory _name, string memory _symbol) {
        id = _id;
        name = _name;
        symbol = _symbol;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        IRegistry(registry).burn(to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _transferFrom(from, to, value);
        IRegistry(registry).burn(to, value);
        return true;
    }

    function mint(address to, uint256 value) external onlyRegistry() {
        balances[to] = balances[to] + value;
        totalSupply = totalSupply + value;
        emit Transfer(registry, to, value);
    }

    function burn(address to, uint256 value) external onlyRegistry() {
        balances[to] = balances[to] - value;
        totalSupply = totalSupply - value;
        emit Transfer(to, registry, value);
    }
}
// File: contracts/bls.sol


pragma solidity >=0.8.4 <0.9.0;

library BLS {
    // Field order
    uint256 constant N = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Negated genarator of G2
    uint256 constant nG2x1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant nG2x0 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant nG2y1 = 17805874995975841540914202342111839520379459829704422454583296818431106115052;
    uint256 constant nG2y0 = 13392588948715843804641432497768002650278120570034223513918757245338268106653;

    uint256 constant FIELD_MASK = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant SIGN_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant ODD_NUM = 0x8000000000000000000000000000000000000000000000000000000000000000;

    function verifySingle(
        uint256[2] memory signature,
        uint256[4] memory pubkey,
        uint256[2] memory message
    ) public view returns (bool) {
        uint256[12] memory input = [
            signature[0],
            signature[1],
            nG2x1,
            nG2x0,
            nG2y1,
            nG2y0,
            message[0],
            message[1],
            pubkey[1],
            pubkey[0],
            pubkey[3],
            pubkey[2]
        ];
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 384, out, 0x20)
            switch success
                case 0 {
                    invalid()
                }
        }
        require(success, "");
        return out[0] != 0;
    }

    function verifyMultiple(
        uint256[2] memory signature,
        uint256[4][] memory pubkeys,
        uint256[2][] memory messages
    ) internal view returns (bool) {
        uint256 size = pubkeys.length;
        require(size > 0, "BLS: number of public key is zero");
        require(
            size == messages.length,
            "BLS: number of public keys and messages must be equal"
        );
        uint256 inputSize = (size + 1) * 6;
        uint256[] memory input = new uint256[](inputSize);
        input[0] = signature[0];
        input[1] = signature[1];
        input[2] = nG2x1;
        input[3] = nG2x0;
        input[4] = nG2y1;
        input[5] = nG2y0;
        for (uint256 i = 0; i < size; i++) {
            input[i * 6 + 6] = messages[i][0];
            input[i * 6 + 7] = messages[i][1];
            input[i * 6 + 8] = pubkeys[i][1];
            input[i * 6 + 9] = pubkeys[i][0];
            input[i * 6 + 10] = pubkeys[i][3];
            input[i * 6 + 11] = pubkeys[i][2];
        }
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(
                sub(gas(), 2000),
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
            switch success
                case 0 {
                    invalid()
                }
        }
        require(success, "");
        return out[0] != 0;
    }

    function hashToPoint(bytes memory data)
        internal
        view
        returns (uint256[2] memory p)
    {
        return mapToPoint(keccak256(data));
    }

    function mapToPoint(bytes32 _x)
        public
        view
        returns (uint256[2] memory p)
    {
        uint256 x = uint256(_x) % N;
        uint256 y;
        bool found = false;
        while (true) {
            y = mulmod(x, x, N);
            y = mulmod(y, x, N);
            y = addmod(y, 3, N);
            (y, found) = sqrt(y);
            if (found) {
                p[0] = x;
                p[1] = y;
                break;
            }
            x = addmod(x, 1, N);
        }
    }


    function mapToPointWithHelp(bytes32 _x, uint256[] memory expected_roots)
        public
        pure
        returns (uint256[2] memory p)
    {
        uint256 x = uint256(_x) % N;
        uint8 i = 0;
        uint256 y;
        uint256 m;
        while (true) {
            y = mulmod(x, x, N);
            y = mulmod(y, x, N);
            y = addmod(y, 3, N);
            m = mulmod(expected_roots[i],expected_roots[i], N);
            if (m == y) {
                p[0] = x;
                p[1] = expected_roots[i];
                break;
            } else if (N-m == y) {
                x = addmod(x, 1, N);
                i += 1;
            } else {
                revert("Wrong expected root.");
            }
        }
    }

    function isValidPublicKey(uint256[4] memory publicKey)
        internal
        pure
        returns (bool)
    {
        if (
            (publicKey[0] >= N) ||
            (publicKey[1] >= N) ||
            (publicKey[2] >= N || (publicKey[3] >= N))
        ) {
            return false;
        } else {
            return isOnCurveG2(publicKey);
        }
    }

    function isValidSignature(uint256[2] memory signature)
        internal
        pure
        returns (bool)
    {
        if ((signature[0] >= N) || (signature[1] >= N)) {
            return false;
        } else {
            return isOnCurveG1(signature);
        }
    }

    function pubkeyToUncompresed(
        uint256[2] memory compressed,
        uint256[2] memory y
    ) internal pure returns (uint256[4] memory uncompressed) {
        uint256 desicion = compressed[0] & SIGN_MASK;
        require(
            desicion == ODD_NUM || y[0] & 1 != 1,
            "BLS: bad y coordinate for uncompressing key"
        );
        uncompressed[0] = compressed[0] & FIELD_MASK;
        uncompressed[1] = compressed[1];
        uncompressed[2] = y[0];
        uncompressed[3] = y[1];
    }

    function signatureToUncompresed(uint256 compressed, uint256 y)
        internal
        pure
        returns (uint256[2] memory uncompressed)
    {
        uint256 desicion = compressed & SIGN_MASK;
        require(
            desicion == ODD_NUM || y & 1 != 1,
            "BLS: bad y coordinate for uncompressing key"
        );
        return [compressed & FIELD_MASK, y];
    }

    function isValidCompressedPublicKey(uint256[2] memory publicKey)
        internal
        view
        returns (bool)
    {
        uint256 x0 = publicKey[0] & FIELD_MASK;
        uint256 x1 = publicKey[1];
        if ((x0 >= N) || (x1 >= N)) {
            return false;
        } else if ((x0 == 0) && (x1 == 0)) {
            return false;
        } else {
            return isOnCurveG2([x0, x1]);
        }
    }

    function isValidCompressedSignature(uint256 signature)
        internal
        view
        returns (bool)
    {
        uint256 x = signature & FIELD_MASK;
        if (x >= N) {
            return false;
        } else if (x == 0) {
            return false;
        }
        return isOnCurveG1(x);
    }

    function isOnCurveG1(uint256[2] memory point)
        internal
        pure
        returns (bool _isOnCurve)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let t0 := mload(point)
            let t1 := mload(add(point, 32))
            let t2 := mulmod(t0, t0, N)
            t2 := mulmod(t2, t0, N)
            t2 := addmod(t2, 3, N)
            t1 := mulmod(t1, t1, N)
            _isOnCurve := eq(t1, t2)
        }
    }

    function isOnCurveG1(uint256 x) internal view returns (bool _isOnCurve) {
        bool callSuccess;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let t0 := x
            let t1 := mulmod(t0, t0, N)
            t1 := mulmod(t1, t0, N)
            t1 := addmod(t1, 3, N)

            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), t1)
            // (N - 1) / 2 = 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            mstore(
                add(freemem, 0x80),
                0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            )
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(
                add(freemem, 0xA0),
                0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            )
            callSuccess := staticcall(
                sub(gas(), 2000),
                5,
                freemem,
                0xC0,
                freemem,
                0x20
            )
            _isOnCurve := eq(1, mload(freemem))
        }
    }

    function isOnCurveG2(uint256[4] memory point)
        internal
        pure
        returns (bool _isOnCurve)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // x0, x1
            let t0 := mload(point)
            let t1 := mload(add(point, 32))
            // x0 ^ 2
            let t2 := mulmod(t0, t0, N)
            // x1 ^ 2
            let t3 := mulmod(t1, t1, N)
            // 3 * x0 ^ 2
            let t4 := add(add(t2, t2), t2)
            // 3 * x1 ^ 2
            let t5 := addmod(add(t3, t3), t3, N)
            // x0 * (x0 ^ 2 - 3 * x1 ^ 2)
            t2 := mulmod(add(t2, sub(N, t5)), t0, N)
            // x1 * (3 * x0 ^ 2 - x1 ^ 2)
            t3 := mulmod(add(t4, sub(N, t3)), t1, N)

            // x ^ 3 + b
            t0 := addmod(
                t2,
                0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5,
                N
            )
            t1 := addmod(
                t3,
                0x009713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2,
                N
            )

            // y0, y1
            t2 := mload(add(point, 64))
            t3 := mload(add(point, 96))
            // y ^ 2
            t4 := mulmod(addmod(t2, t3, N), addmod(t2, sub(N, t3), N), N)
            t3 := mulmod(shl(1, t2), t3, N)

            // y ^ 2 == x ^ 3 + b
            _isOnCurve := and(eq(t0, t4), eq(t1, t3))
        }
    }

    function isOnCurveG2(uint256[2] memory x)
        internal
        view
        returns (bool _isOnCurve)
    {
        bool callSuccess;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // x0, x1
            let t0 := mload(add(x, 0))
            let t1 := mload(add(x, 32))
            // x0 ^ 2
            let t2 := mulmod(t0, t0, N)
            // x1 ^ 2
            let t3 := mulmod(t1, t1, N)
            // 3 * x0 ^ 2
            let t4 := add(add(t2, t2), t2)
            // 3 * x1 ^ 2
            let t5 := addmod(add(t3, t3), t3, N)
            // x0 * (x0 ^ 2 - 3 * x1 ^ 2)
            t2 := mulmod(add(t2, sub(N, t5)), t0, N)
            // x1 * (3 * x0 ^ 2 - x1 ^ 2)
            t3 := mulmod(add(t4, sub(N, t3)), t1, N)
            // x ^ 3 + b
            t0 := add(
                t2,
                0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5
            )
            t1 := add(
                t3,
                0x009713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2
            )

            // is non residue ?
            t0 := addmod(mulmod(t0, t0, N), mulmod(t1, t1, N), N)
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), t0)
            // (N - 1) / 2 = 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            mstore(
                add(freemem, 0x80),
                0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            )
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(
                add(freemem, 0xA0),
                0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            )
            callSuccess := staticcall(
                sub(gas(), 2000),
                5,
                freemem,
                0xC0,
                freemem,
                0x20
            )
            _isOnCurve := eq(1, mload(freemem))
        }
    }

    function isNonResidueFP(uint256 e)
        internal
        view
        returns (bool isNonResidue)
    {
        bool callSuccess;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), e)
            // (N - 1) / 2 = 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            mstore(
                add(freemem, 0x80),
                0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            )
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(
                add(freemem, 0xA0),
                0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            )
            callSuccess := staticcall(
                sub(gas(), 2000),
                5,
                freemem,
                0xC0,
                freemem,
                0x20
            )
            isNonResidue := eq(1, mload(freemem))
        }
        require(callSuccess, "BLS: isNonResidueFP modexp call failed");
        return !isNonResidue;
    }

    function isNonResidueFP2(uint256[2] memory e)
        internal
        view
        returns (bool isNonResidue)
    {
        uint256 a = addmod(mulmod(e[0], e[0], N), mulmod(e[1], e[1], N), N);
        bool callSuccess;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), a)
            // (N - 1) / 2 = 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            mstore(
                add(freemem, 0x80),
                0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            )
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(
                add(freemem, 0xA0),
                0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            )
            callSuccess := staticcall(
                sub(gas(), 2000),
                5,
                freemem,
                0xC0,
                freemem,
                0x20
            )
            isNonResidue := eq(1, mload(freemem))
        }
        require(callSuccess, "BLS: isNonResidueFP2 modexp call failed");
        return !isNonResidue;
    }

    function sqrt(uint256 xx) internal view returns (uint256 x, bool hasRoot) {
        bool callSuccess;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), xx)
            // (N + 1) / 4 = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52
            mstore(
                add(freemem, 0x80),
                0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52
            )
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(
                add(freemem, 0xA0),
                0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            )
            callSuccess := staticcall(
                sub(gas(), 2000),
                5,
                freemem,
                0xC0,
                freemem,
                0x20
            )
            x := mload(freemem)
            hasRoot := eq(xx, mulmod(x, x, N))
        }
        require(callSuccess, "BLS: sqrt modexp call failed");
    }
}

// File: contracts/bytes.sol


/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// File: contracts/user.sol


pragma solidity >=0.8.0 <0.9.0;




contract MixinUser is Registrable {
    using BytesLib for bytes;

    bytes public members;

    constructor(bytes memory _members) {
        members = _members;
    }

    function run(address asset, uint256 amount, bytes memory extra) external onlyRegistry() returns (bool result) {
        if (extra.length < 24) {
            return true;
        }
        address process = extra.toAddress(0);
        IERC20(asset).approve(process, 0);
        IERC20(asset).approve(process, amount);
        bytes memory input = extra.slice(20, extra.length - 20);
        (result, input) = process.call(input);
        try IRegistry(registry).claim(asset, amount) {} catch {}
        return result;
    }
}
// File: contracts/registry.sol


pragma solidity >=0.8.0 <0.9.0;






contract Registry is IRegistry {
    using BytesLib for bytes;
    using BLS for uint256[2];
    using BLS for bytes;

    event UserCreated(address at, bytes members);
    event AssetCreated(address at, uint id);
    event MixinTransaction(bytes);
    event MixinEvent(Event evt);

    uint256 public constant VERSION = 1;
    uint128 public constant PID = 1;
    uint256 constant BALANCE = 1;

    uint256[4] public GROUP;
    uint64 public INBOUND = 0;
    uint64 public OUTBOUND = 0;
    bool public HALTED = false;

    mapping(address => bytes) public users;
    mapping(address => uint128) public assets;
    mapping(uint => address) public contracts;
    mapping(uint128 => uint256) public balances;
    address[] public addresses;
    uint128[] public deposits;

    struct Event {
        uint64 nonce;
        address user;
        address asset;
        uint256 amount;
        bytes extra;
        uint64 timestamp;
        uint256[2] sig;
    }

    function iterate(bytes memory raw) public {
        require(raw.length == 256, "invalid input size");
        uint256[4] memory group = [raw.toUint256(0), raw.toUint256(32), raw.toUint256(64), raw.toUint256(96)];
        uint256[2] memory sig1 = [raw.toUint256(128), raw.toUint256(160)];
        uint256[2] memory sig2 = [raw.toUint256(192), raw.toUint256(224)];
        uint256[2] memory message = raw.slice(0, 128).hashToPoint();
        require(sig1.verifySingle(GROUP, message));
        require(sig2.verifySingle(group, message));
        GROUP = group;
    }

    function halt(bytes memory raw) public {
        uint256[2] memory sig = [raw.toUint256(0), raw.toUint256(32)];
        uint256[2] memory message = bytes("HALT").hashToPoint();
        require(sig.verifySingle(GROUP, message));
        HALTED = true;
    }

    function evolve(bytes memory raw) public {
        require(HALTED, "invalid state");
        Registry next = Registry(raw.toAddress(0));
        uint256[2] memory sig = [raw.toUint256(20), raw.toUint256(52)];
        uint256[2] memory message = raw.slice(0, 20).hashToPoint();
        require(sig.verifySingle(GROUP, message));
        require(next.INBOUND() == INBOUND);
        require(next.OUTBOUND() == OUTBOUND);
        require(next.PID() != PID);
        for (uint i = 0; i < addresses.length; i++) {
            address addr = next.addresses(i);
            require(addr == addresses[i]);
            bytes memory members = users[addr];
            if (members.length > 0) {
                uint id = uint256(keccak256(members));
                require(next.contracts(id) == addr);
                Registrable(addr).evolve(address(next));
            } else {
                uint128 asset = assets[addr];
                require(next.contracts(asset) == addr);
                Registrable(addr).evolve(address(next));
            }
        }
        for (uint i = 0; i < deposits.length; i++) {
            uint128 asset = deposits[i];
            uint256 amount = balances[asset] - BALANCE;
            bytes memory user = new bytes(0); // TODO should be the new regsitry PID
            bytes memory extra = new bytes(0); // TODO should be ABI of pure deposit to registry
            bytes memory log = buildMixinTransaction(OUTBOUND, user, asset, amount, extra);
            emit MixinTransaction(log);
            OUTBOUND = OUTBOUND + 1;
        }
    }

    function claim(address asset, uint256 amount) external returns (bool) {
        require(users[msg.sender].length > 0, "invalid user");
        require(assets[asset] > 0, "invalid asset");
        MixinAsset(asset).burn(msg.sender, amount);
        sendMixinTransaction(msg.sender, asset, amount);
        return true;
    }

    function burn(address user, uint256 amount) external returns (bool) {
        require(assets[msg.sender] > 0, "invalid asset");
        if (users[user].length == 0) {
            return true;
        }
        MixinAsset(msg.sender).burn(user, amount);
        sendMixinTransaction(user, msg.sender, amount);
        return true;
    }

    function sendMixinTransaction(address user, address asset, uint256 amount) internal {
        uint256 balance = balances[assets[asset]];
        bytes memory extra = new bytes(0);
        bytes memory log = buildMixinTransaction(OUTBOUND, users[user], assets[asset], amount, extra);
        emit MixinTransaction(log);
        balances[assets[asset]] = balance - amount;
        OUTBOUND = OUTBOUND + 1;
    }

    // process || nonce || asset || amount || extra || timestamp || members || threshold || sig
    function buildMixinTransaction(uint64 nonce, bytes memory receiver, uint128 asset, uint256 amount, bytes memory extra) internal view returns (bytes memory) {
        require(extra.length < 128, "extra too large");
        bytes memory raw = uint128ToFixedBytes(PID);
        raw = raw.concat(uint64ToFixedBytes(nonce));
        raw = raw.concat(uint128ToFixedBytes(asset));
        (bytes memory ab, uint16 al) = uint256ToVarBytes(amount);
        raw = raw.concat(uint16ToFixedBytes(al));
        raw = raw.concat(ab);
        raw = raw.concat(uint16ToFixedBytes(uint16(extra.length)));
        raw = raw.concat(extra);
        raw = raw.concat(uint64ToFixedBytes(uint64(block.timestamp)));
        raw = raw.concat(receiver);
        raw = raw.concat(new bytes(2));
        return raw;
    }

    // process || nonce || asset || amount || extra || timestamp || members || threshold || sig
    function mixin(bytes memory raw) public returns (bool) {
        require(!HALTED, "invalid state");
        require(raw.length >= 141, "event data too small");

        Event memory evt;
        uint256 offset = 0;

        uint128 id = raw.toUint128(offset);
        require(id == PID, "invalid process");
        offset = offset + 16;

        evt.nonce = raw.toUint64(offset);
        require(evt.nonce == INBOUND, "invalid nonce");
        INBOUND = INBOUND + 1;
        offset = offset + 8;

        (offset, id, evt.amount) = parseEventAsset(raw, offset);
        (offset, evt.extra, evt.timestamp) = parseEventExtra(raw, offset);
        (offset, evt.user) = parseEventUser(raw, offset);
        (evt.asset, evt.extra) = parseEventInput(id, evt.extra);

        offset = offset + 2;
        evt.sig = [raw.toUint256(offset), raw.toUint256(offset+32)];
        uint256[2] memory message = raw.slice(0, offset-2).concat(new bytes(2)).hashToPoint();
        require(evt.sig.verifySingle(GROUP, message), "invalid signature");

        offset = offset + 64;
        require(raw.length == offset, "malformed event encoding");

        uint256 balance = balances[assets[evt.asset]];
        if (balance == 0) {
            deposits.push(assets[evt.asset]);
            balance = BALANCE;
        }
        balances[assets[evt.asset]] = balance + evt.amount;

        emit MixinEvent(evt);
        MixinAsset(evt.asset).mint(evt.user, evt.amount);
        return MixinUser(evt.user).run(evt.asset, evt.amount, evt.extra);
    }

    function parseEventExtra(bytes memory raw, uint offset) internal pure returns(uint, bytes memory, uint64) {
        uint size = raw.toUint16(offset);
        offset = offset + 2;
        bytes memory extra = raw.slice(offset, size);
        offset = offset + size;
        uint64 timestamp = raw.toUint64(offset);
        offset = offset + 8;
        return (offset, extra, timestamp);
    }

    function parseEventAsset(bytes memory raw, uint offset) internal pure returns(uint, uint128, uint256) {
        uint128 id = raw.toUint128(offset);
        require(id > 0, "invalid asset");
        offset = offset + 16;
        uint size = raw.toUint16(offset);
        offset = offset + 2;
        require(size <= 32, "integer out of bounds");
        uint256 amount = new bytes(32 - size).concat(raw.slice(offset, size)).toUint256(0);
        offset = offset + size;
        return (offset, id, amount);
    }

    function parseEventUser(bytes memory raw, uint offset) internal returns (uint, address) {
        uint16 size = raw.toUint16(offset);
        size = 2 + size * 16 + 2;
        bytes memory members = raw.slice(offset, size);
        offset = offset + size;
        address user = getOrCreateUserContract(members);
        return (offset, user);
    }

    function parseEventInput(uint128 id, bytes memory extra) internal returns (address, bytes memory) {
        uint offset = 0;
        uint16 size = extra.toUint16(offset);
        offset = offset + 2;
        string memory symbol = string(extra.slice(offset, size));
        offset = offset + size;
        size = extra.toUint16(offset);
        offset = offset + 2;
        string memory name = string(extra.slice(offset, size));
        offset = offset + size;
        bytes memory input = extra.slice(offset, extra.length - offset);
        address asset = getOrCreateAssetContract(id, symbol, name);
        return (asset, input);
    }

    function getOrCreateAssetContract(uint128 id, string memory symbol, string memory name) internal returns (address) {
        address old = contracts[id];
        if (old != address(0)) {
            return old;
        }
        bytes memory code = getAssetContractCode(id, symbol, name);
        address asset = getContractAddress(code);
        if (assets[asset] > 0) {
            return asset;
        }
        address addr = deploy(code, VERSION);
        require(addr == asset, "malformed asset contract address");
        assets[asset] = id;
        contracts[id] = asset;
        addresses.push(asset);
        emit AssetCreated(asset, id);
        return asset;
    }

    function getOrCreateUserContract(bytes memory members) internal returns (address) {
        uint id = uint256(keccak256(members));
        address old = contracts[id];
        if (old != address(0)) {
            return old;
        }
        bytes memory code = getUserContractCode(members);
        address user = getContractAddress(code);
        if (users[user].length > 0) {
            return user;
        }
        address addr = deploy(code, VERSION);
        require(addr == user, "malformed user contract address");
        users[user] = members;
        contracts[id] = user;
        addresses.push(user);
        emit UserCreated(user, members);
        return user;
    }

    function getUserContractCode(bytes memory members) internal pure returns (bytes memory) {
        bytes memory code = type(MixinUser).creationCode;
        bytes memory args = abi.encode(members);
        return abi.encodePacked(code, args);
    }

    function getAssetContractCode(uint id, string memory symbol, string memory name) internal pure returns (bytes memory) {
        bytes memory code = type(MixinAsset).creationCode;
        bytes memory args = abi.encode(id, name, symbol);
        return abi.encodePacked(code, args);
    }

    function getContractAddress(bytes memory code) internal view returns (address) {
        code = abi.encodePacked(bytes1(0xff), address(this), VERSION, keccak256(code));
        return address(uint160(uint(keccak256(code))));
    }

    function deploy(bytes memory bytecode, uint _salt) internal returns (address) {
        address addr;
        assembly {
            addr := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                _salt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }


    function uint16ToFixedBytes(uint16 x) internal pure returns (bytes memory) {
        bytes memory c = new bytes(2);
        bytes2 b = bytes2(x);
        for (uint i=0; i < 2; i++) {
            c[i] = b[i];
        }
        return c;
    }

    function uint64ToFixedBytes(uint64 x) internal pure returns (bytes memory) {
        bytes memory c = new bytes(8);
        bytes8 b = bytes8(x);
        for (uint i=0; i < 8; i++) {
            c[i] = b[i];
        }
        return c;
    }

    function uint128ToFixedBytes(uint128 x) internal pure returns (bytes memory) {
        bytes memory c = new bytes(16);
        bytes16 b = bytes16(x);
        for (uint i=0; i < 16; i++) {
            c[i] = b[i];
        }
        return c;
    }

    function uint256ToVarBytes(uint256 x) internal pure returns (bytes memory, uint16) {
        bytes memory c = new bytes(32);
        bytes32 b = bytes32(x);
        uint16 offset = 0;
        for (uint16 i=0; i < 32; i++) {
            c[i] = b[i];
            if (c[i] > 0 && offset == 0) {
                offset = i;
            }
        }
        uint16 size = 32 - offset;
        return (c.slice(offset, 32-offset), size);
    }
}