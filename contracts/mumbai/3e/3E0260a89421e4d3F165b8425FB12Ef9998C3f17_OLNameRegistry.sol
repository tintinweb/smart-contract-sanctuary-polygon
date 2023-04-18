pragma solidity ^0.8.17;

// SPDX-License-Identifier: UNLICENSED
interface OLNameStoreInterface {
    // Deploy status
    function getDeployedStatus() external view returns (bool);

    function setPermissions(address user, uint8 perms) external;

    function getPermissions(address user) external view returns (uint8);

    function canRead(address user) external view returns (bool);

    function canWrite(address user) external view returns (bool);

    function existsBytesData(bytes32 key) external view returns (bool);

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function deleteBytes(bytes32 _key) external;

    function registerAddress(address _address) external;

    function isAddressRegistered(address _address) external view returns (bool);

    function deleteAddressRegistry(address _address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

function toString(address account) pure returns(string memory) {
    return toString(abi.encodePacked(account));
}

function toString(uint256 value) pure returns(string memory) {
    return toString(abi.encodePacked(value));
}

function toString(bytes32 value) pure returns(string memory) {
    return toString(abi.encodePacked(value));
}

function toString(bytes memory data) pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

uint8 constant READ_ONLY = 1;
uint8 constant WRITE_ONLY = 2;
uint8 constant READ_WRITE = 3;

struct TokenLocator {
    uint256 tokenId;
    string collectionId;
    uint32 chain;
}

struct SecurityProps {
    string unused; // previously secret
    string exchange;
    string metadataCid;
    string docRoot;
    string version; // previously owner
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

string constant NOT_OWNER_WRITER = "Not owner/writer";
string constant NOT_OWNER_READER = "Not owner/reader";
string constant TOKEN_ALREADY_ADDED = "Token already added";
string constant REGISTRY_NOT_FOUND = "Registry not found";
string constant REGISTRY_ALREADY_ADDED = "Registry already exists";
string constant INVALID_ADDRESS = "Invalid address";

pragma solidity ^0.8.17;

// SPDX-License-Identifier: UNLICENSED

import "./interfaces/OLNameStoreInterface.sol";
import "./libs/Definitions.sol";

import "./Ownable.sol";
import "./libs/Errors.sol";
import "./libs/Convert.sol";
import { Seriality } from "../../Seriality/src/Seriality.sol";

struct Registry {
    string nameHash;
    string regAddress;
    string version;
    string avatar;
}

contract OLNameRegistry is Ownable, Seriality {
    OLNameStoreInterface olNameStore = OLNameStoreInterface(address(0));

    constructor(OLNameStoreInterface _storageAddress) Ownable() {
        olNameStore = OLNameStoreInterface(_storageAddress);
    }

    function requireOwnerWriter() public view {
        require(owner == msg.sender || olNameStore.canWrite(msg.sender), NOT_OWNER_WRITER);
    }

    function requireOwnerReader() public view {
        require(owner == msg.sender || olNameStore.canRead(msg.sender), NOT_OWNER_READER);
    }

    function registerName(bytes32 nameHash, address _address, string calldata avatar) external {
        requireOwnerWriter();
        require(!existsRegistry(nameHash), REGISTRY_ALREADY_ADDED);
        require(_address != address(0), INVALID_ADDRESS);

        Registry memory data;
        data.nameHash = toString(nameHash);
        data.regAddress = toString(_address);
        data.version = "{ver:'1.000'}";
        data.avatar = avatar;

        setRegistry(nameHash, data);
        olNameStore.registerAddress(_address); // set address as registered
    }

    function getRegistry(bytes32 nameHash) public returns (Registry memory) {
        requireOwnerWriter();
        bytes memory buffer = olNameStore.getBytes(nameHash);
        return deserializeRegistry(buffer);
    }

    function updateName(bytes32 oldNameHash, bytes32 newNameHash, address _address) external {
        requireOwnerWriter();
        require(usernameAvailable(newNameHash), REGISTRY_ALREADY_ADDED);

        Registry memory registry = getRegistry(oldNameHash);
        require(keccak256(abi.encodePacked(registry.regAddress)) == keccak256(abi.encodePacked(toString(_address))), REGISTRY_NOT_FOUND);

        registry.nameHash = toString(newNameHash);
        setRegistry(newNameHash, registry);
        olNameStore.deleteBytes(newNameHash);
    }

    function updateAddress(bytes32 nameHash, address oldAddress, address newAddress) external {
        requireOwnerWriter();
        Registry memory registry = getRegistry(nameHash);
        require(keccak256(abi.encodePacked(registry.regAddress)) == keccak256(abi.encodePacked(toString(oldAddress))), REGISTRY_NOT_FOUND);
        require(!isAddressRegistered(newAddress), REGISTRY_ALREADY_ADDED);
        require(newAddress != address(0), INVALID_ADDRESS);

        registry.regAddress = toString(newAddress);
        setRegistry(nameHash, registry);
        olNameStore.deleteAddressRegistry(oldAddress);
        olNameStore.registerAddress(newAddress);
    }

    function isAddressRegistered(address _address) public view returns (bool) {
        return olNameStore.isAddressRegistered(_address);
    }

    function existsRegistry(bytes32 nameHash) public view returns (bool) {
        return olNameStore.existsBytesData(nameHash);
    }

    function usernameAvailable(bytes32 nameHash) public view returns (bool) {
        return !olNameStore.existsBytesData(nameHash);
    }

    event logFoo3(bytes32 key, Registry data);
    event logFoo4(bytes32 key, bytes data);
    event logFoo5(bytes32 key, bytes data);

    function setRegistry(bytes32 nameHash, Registry memory _value) internal {
        bytes memory buffer = serializeRegistry(_value);
        olNameStore.setBytes(nameHash, buffer);
        emit logFoo5(nameHash, olNameStore.getBytes(nameHash));
    }

    event logFoo6(uint8 idx, uint256 bufferSize, bytes buffer);

    function serializeRegistry(Registry memory props) internal returns (bytes memory) {
        uint256 bufferSize = sizeOfString(props.regAddress) +
            sizeOfString(props.avatar) +
            sizeOfString(props.nameHash) +
            sizeOfString(props.version);

        uint256 offset = bufferSize;
        bytes memory buffer = new bytes(bufferSize);

        stringToBytes(offset, bytes(props.version), buffer);
        offset -= sizeOfString(props.version);

        stringToBytes(offset, bytes(props.avatar), buffer);
        offset -= sizeOfString(props.avatar);

        stringToBytes(offset, bytes(props.nameHash), buffer);
        offset -= sizeOfString(props.nameHash);

        stringToBytes(offset, bytes(props.regAddress), buffer);
        offset -= sizeOfString(props.regAddress);

        emit logFoo6(3, buffer.length, buffer);
        return buffer;
    }

    function deserializeRegistry(bytes memory buffer) internal returns (Registry memory) {
        Registry memory props;

        uint256 bufferSize = buffer.length;
        uint256 offset = bufferSize;
        emit logFoo6(10, bufferSize, buffer);
        emit logFoo6(11, buffer.length, buffer);

        props.version = new string(getStringSize(offset, buffer));
        bytesToString(offset, buffer, bytes(props.version));
        offset -= sizeOfString(props.version);

        props.avatar = new string(getStringSize(offset, buffer));
        bytesToString(offset, buffer, bytes(props.avatar));
        offset -= sizeOfString(props.avatar);

        props.nameHash = new string(getStringSize(offset, buffer));
        bytesToString(offset, buffer, bytes(props.nameHash));
        offset -= sizeOfString(props.nameHash);

        props.regAddress = new string(getStringSize(offset, buffer));
        bytesToString(offset, buffer, bytes(props.regAddress));
        offset -= sizeOfString(props.regAddress);

        emit logFoo6(10, bufferSize, buffer);

        return props;
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

/** @title Ownership Contract */
contract Ownable {
    address internal owner;

    string internal constant NOT_OWNER = "Not owner";

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, NOT_OWNER);
        _;
    }

    function passOwnership(address _newOwner) internal onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function kill() internal onlyOwner {
        selfdestruct(payable(owner));
    }

    function getOwner() internal view returns (address) {
        return owner;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title BytesToTypes
 * @dev The BytesToTypes contract converts the memory byte arrays to the standard solidity types
 * @author [email protected]
 */

contract BytesToTypes {
	function bytesToAddress(
		uint _offst,
		bytes memory _input
	) internal pure returns (address _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToBool(
		uint _offst,
		bytes memory _input
	) internal pure returns (bool _output) {
		uint8 x;
		assembly {
			x := mload(add(_input, _offst))
		}
		x == 0 ? _output = false : _output = true;
	}

	function getStringSize(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint size) {
		assembly {
			size := mload(add(_input, _offst))
			let chunk_count := add(div(size, 32), 1) // chunk_count = size/32 + 1

			if gt(mod(size, 32), 0) {
				// if size%32 > 0
				chunk_count := add(chunk_count, 1)
			}

			size := mul(chunk_count, 32) // first 32 bytes reseves for size in strings
		}
	}

	function bytesToString(
		uint _offst,
		bytes memory _input,
		bytes memory _output
	) internal pure {
		uint size = 32;
		assembly {
			let chunk_count

			size := mload(add(_input, _offst))
			chunk_count := add(div(size, 32), 1) // chunk_count = size/32 + 1

			if gt(mod(size, 32), 0) {
				chunk_count := add(chunk_count, 1) // chunk_count++
			}

			for {
				let index := 0
			} lt(index, chunk_count) {
				index := add(index, 1)
			} {
				mstore(add(_output, mul(index, 32)), mload(add(_input, _offst)))
				_offst := sub(_offst, 32) // _offst -= 32
			}
		}
	}

	function bytesToBytes32(
		uint _offst,
		bytes memory _input,
		bytes32 _output
	) internal pure {
		assembly {
			mstore(_output, add(_input, _offst))
			mstore(add(_output, 32), add(add(_input, _offst), 32))
		}
	}

	function bytesToInt8(
		uint _offst,
		bytes memory _input
	) internal pure returns (int8 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt16(
		uint _offst,
		bytes memory _input
	) internal pure returns (int16 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt24(
		uint _offst,
		bytes memory _input
	) internal pure returns (int24 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt32(
		uint _offst,
		bytes memory _input
	) internal pure returns (int32 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt40(
		uint _offst,
		bytes memory _input
	) internal pure returns (int40 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt48(
		uint _offst,
		bytes memory _input
	) internal pure returns (int48 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt56(
		uint _offst,
		bytes memory _input
	) internal pure returns (int56 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt64(
		uint _offst,
		bytes memory _input
	) internal pure returns (int64 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt72(
		uint _offst,
		bytes memory _input
	) internal pure returns (int72 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt80(
		uint _offst,
		bytes memory _input
	) internal pure returns (int80 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt88(
		uint _offst,
		bytes memory _input
	) internal pure returns (int88 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt96(
		uint _offst,
		bytes memory _input
	) internal pure returns (int96 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt104(
		uint _offst,
		bytes memory _input
	) internal pure returns (int104 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt112(
		uint _offst,
		bytes memory _input
	) internal pure returns (int112 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt120(
		uint _offst,
		bytes memory _input
	) internal pure returns (int120 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt128(
		uint _offst,
		bytes memory _input
	) internal pure returns (int128 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt136(
		uint _offst,
		bytes memory _input
	) internal pure returns (int136 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt144(
		uint _offst,
		bytes memory _input
	) internal pure returns (int144 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt152(
		uint _offst,
		bytes memory _input
	) internal pure returns (int152 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt160(
		uint _offst,
		bytes memory _input
	) internal pure returns (int160 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt168(
		uint _offst,
		bytes memory _input
	) internal pure returns (int168 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt176(
		uint _offst,
		bytes memory _input
	) internal pure returns (int176 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt184(
		uint _offst,
		bytes memory _input
	) internal pure returns (int184 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt192(
		uint _offst,
		bytes memory _input
	) internal pure returns (int192 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt200(
		uint _offst,
		bytes memory _input
	) internal pure returns (int200 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt208(
		uint _offst,
		bytes memory _input
	) internal pure returns (int208 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt216(
		uint _offst,
		bytes memory _input
	) internal pure returns (int216 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt224(
		uint _offst,
		bytes memory _input
	) internal pure returns (int224 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt232(
		uint _offst,
		bytes memory _input
	) internal pure returns (int232 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt240(
		uint _offst,
		bytes memory _input
	) internal pure returns (int240 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt248(
		uint _offst,
		bytes memory _input
	) internal pure returns (int248 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToInt256(
		uint _offst,
		bytes memory _input
	) internal pure returns (int256 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint8(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint8 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint16(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint16 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint24(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint24 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint32(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint32 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint40(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint40 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint48(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint48 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint56(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint56 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint64(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint64 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint72(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint72 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint80(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint80 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint88(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint88 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint96(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint96 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint104(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint104 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint112(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint112 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint120(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint120 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint128(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint128 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint136(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint136 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint144(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint144 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint152(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint152 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint160(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint160 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint168(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint168 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint176(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint176 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint184(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint184 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint192(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint192 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint200(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint200 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint208(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint208 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint216(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint216 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint224(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint224 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint232(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint232 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint240(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint240 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint248(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint248 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}

	function bytesToUint256(
		uint _offst,
		bytes memory _input
	) internal pure returns (uint256 _output) {
		assembly {
			_output := mload(add(_input, _offst))
		}
	}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
/**
 * @title Seriality
 * @dev The Seriality contract is the main interface for serializing data using the TypeToBytes, BytesToType and SizeOf
 * @author [email protected]
 */

import "./BytesToTypes.sol";
import "./TypesToBytes.sol";
import "./SizeOf.sol";

contract Seriality is BytesToTypes, TypesToBytes, SizeOf {
	constructor() {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title SizeOf
 * @dev The SizeOf return the size of the solidity types in byte
 * @author [email protected]
 */

contract SizeOf {
	function sizeOfString(
		string memory _in
	) internal pure returns (uint _size) {
		_size = bytes(_in).length / 32;
		if (bytes(_in).length % 32 != 0) _size++;

		_size++; // first 32 bytes is reserved for the size of the string
		_size *= 32;
	}

	function sizeOfInt(uint16 _postfix) internal pure returns (uint size) {
		assembly {
			switch _postfix
			case 8 {
				size := 1
			}
			case 16 {
				size := 2
			}
			case 24 {
				size := 3
			}
			case 32 {
				size := 4
			}
			case 40 {
				size := 5
			}
			case 48 {
				size := 6
			}
			case 56 {
				size := 7
			}
			case 64 {
				size := 8
			}
			case 72 {
				size := 9
			}
			case 80 {
				size := 10
			}
			case 88 {
				size := 11
			}
			case 96 {
				size := 12
			}
			case 104 {
				size := 13
			}
			case 112 {
				size := 14
			}
			case 120 {
				size := 15
			}
			case 128 {
				size := 16
			}
			case 136 {
				size := 17
			}
			case 144 {
				size := 18
			}
			case 152 {
				size := 19
			}
			case 160 {
				size := 20
			}
			case 168 {
				size := 21
			}
			case 176 {
				size := 22
			}
			case 184 {
				size := 23
			}
			case 192 {
				size := 24
			}
			case 200 {
				size := 25
			}
			case 208 {
				size := 26
			}
			case 216 {
				size := 27
			}
			case 224 {
				size := 28
			}
			case 232 {
				size := 29
			}
			case 240 {
				size := 30
			}
			case 248 {
				size := 31
			}
			case 256 {
				size := 32
			}
			default {
				size := 32
			}
		}
	}

	function sizeOfUint(uint16 _postfix) internal pure returns (uint size) {
		return sizeOfInt(_postfix);
	}

	function sizeOfAddress() internal pure returns (uint8) {
		return 20;
	}

	function sizeOfBool() internal pure returns (uint8) {
		return 1;
	}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title TypesToBytes
 * @dev The TypesToBytes contract converts the standard solidity types to the byte array
 * @author [email protected]
 */

contract TypesToBytes {
	constructor() {}

	function addressToBytes(
		uint _offst,
		address _input,
		bytes memory _output
	) internal pure {
		assembly {
			mstore(add(_output, _offst), _input)
		}
	}

	function bytes32ToBytes(
		uint _offst,
		bytes32 _input,
		bytes memory _output
	) internal pure {
		assembly {
			mstore(add(_output, _offst), _input)
			mstore(add(add(_output, _offst), 32), add(_input, 32))
		}
	}

	function boolToBytes(
		uint _offst,
		bool _input,
		bytes memory _output
	) internal pure {
		uint8 x = _input == false ? 0 : 1;
		assembly {
			mstore(add(_output, _offst), x)
		}
	}

	function stringToBytes(
		uint _offst,
		bytes memory _input,
		bytes memory _output
	) internal pure {
		uint256 stack_size = _input.length / 32;
		if (_input.length % 32 > 0) stack_size++;

		assembly {
			stack_size := add(stack_size, 1) //adding because of 32 first bytes memory as the length
			for {
				let index := 0
			} lt(index, stack_size) {
				index := add(index, 1)
			} {
				mstore(add(_output, _offst), mload(add(_input, mul(index, 32))))
				_offst := sub(_offst, 32)
			}
		}
	}

	function intToBytes(
		uint _offst,
		int _input,
		bytes memory _output
	) internal pure {
		assembly {
			mstore(add(_output, _offst), _input)
		}
	}

	function uintToBytes(
		uint _offst,
		uint _input,
		bytes memory _output
	) internal pure {
		assembly {
			mstore(add(_output, _offst), _input)
		}
	}
}