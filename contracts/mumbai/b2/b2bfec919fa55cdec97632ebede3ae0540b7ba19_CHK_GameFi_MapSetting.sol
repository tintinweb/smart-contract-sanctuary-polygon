/**
 *Submitted for verification at polygonscan.com on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
                        if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
                string memory table = _TABLE;
                                                        string memory result = new string(4 * ((data.length + 2) / 3));
        assembly {
                        let tablePtr := add(table, 1)
                        let resultPtr := add(result, 32)
                        for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {
            } {
                                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)             }
                                    switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }
        return result;
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
library ZString {
    function size(string memory str) internal pure returns (uint256) {
        bytes memory bin = bytes(str);
        return bin.length;
    }
    function cut(
        string memory str,
        uint256 posFrom,
        uint256 posTo
    ) internal pure returns (string memory) {
        if (posFrom == posTo) return "";
        if (posFrom > posTo) {
            uint256 t = posFrom;
            posFrom = posTo;
            posTo = t;
        }
        bytes memory bin = bytes(str);
        if (posFrom >= bin.length) return "";
        if (posTo >= bin.length) posTo = bin.length - 1;
        bytes memory buf = new bytes(posTo - posFrom);
        for (uint256 i = posFrom; i < posTo; i++) {
            buf[i - posFrom] = bin[i];
        }
        return string(buf);
    }
    function sub(
        string memory str,
        uint256 pos,
        uint256 len
    ) internal pure returns (string memory) {
        bytes memory bin = bytes(str);
        if (pos < 0) {
            pos = 0;
            len += pos;
        }
        if (pos < 0 || len < 1) return "";
        if (pos + len > bin.length) len = bin.length - pos;
        bytes memory buf = new bytes(len);
        uint256 j = 0;
        for (uint256 i = pos; i < pos + len; i++) {
            buf[j] = bin[i];
            j++;
        }
        return string(buf);
    }
    function sub(string memory str, uint256 pos)
        internal
        pure
        returns (string memory)
    {
        if (pos < 1) return str;
        bytes memory bin = bytes(str);
        if (pos >= bin.length) return "";
        bytes memory buf = new bytes(bin.length - pos);
        uint256 j = 0;
        for (uint256 i = pos; i < bin.length; i++) {
            buf[j] = bin[i];
            j++;
        }
        return string(buf);
    }
    function find(string memory str, string memory chr)
        internal
        pure
        returns (int256)
    {
        bytes memory bstr = bytes(str);
        bytes memory bchr = bytes(chr);
        if (bstr.length < bchr.length) {
            return -1;
        }
        for (uint256 i = 0; i < bstr.length - bchr.length; i++) {
            bool f = true;
            for (uint256 j = 0; j < bchr.length; j++) {
                if (bchr[j] != bstr[i]) {
                    f = false;
                    break;
                }
            }
            if (f) return int256(i);
        }
        return -1;
    }
    function equal(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        uint256 la = bytes(a).length;
        uint256 lb = bytes(b).length;
        if (la != lb) return false;
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
    function startsWith(string memory str, string memory lead)
        internal
        pure
        returns (bool)
    {
        uint256 la = bytes(str).length;
        uint256 lb = bytes(lead).length;
        if (lb > la) return false;
        if (lb == la)
            return
                keccak256(abi.encodePacked(str)) ==
                keccak256(abi.encodePacked(lead));
        string memory c = sub(str, 0, lb);
        return
            keccak256(abi.encodePacked(c)) == keccak256(abi.encodePacked(lead));
    }
    function concat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    function concat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory) {
        return concat(_a, _b, _c, _d, "");
    }
    function concat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        return concat(_a, _b, _c, "", "");
    }
    function concat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory)
    {
        return concat(_a, _b, "", "", "");
    }
    function pad(
        string memory str,
        string memory chr,
        uint256 len
    ) internal pure returns (string memory) {
        bytes memory bstr = bytes(str);
        if (bstr.length >= len) return str;
        bytes memory bchr = bytes(chr);
        if (bchr.length < 1) return str;
        bytes memory tmp = new bytes(len);
        uint256 p = len - bstr.length;
        for (uint256 i = 0; i < p; i++) tmp[i] = bchr[0];
        for (uint256 j = 0; j < bstr.length; j++) {
            tmp[p + j] = bstr[j];
        }
        return string(tmp);
    }
}
contract CHK_GameFi_MapSetting is Ownable, ERC165 {
    struct CHK_GameFi_MapItem {
        uint16 id;
        string key;
        string name;
        uint32 max_units;
    }
    uint16 _length;
    mapping(uint16 => CHK_GameFi_MapItem) _values;
    constructor() {
        _length = 1;
        _values[1] = CHK_GameFi_MapItem(1, "HK", "HongKong", 321831);
    }
    function length() public view returns (uint16) {
        return _length;
    }
    function item(uint16 id) external view returns (CHK_GameFi_MapItem memory) {
        require(id > 0 && id <= _length, "Non-exists map id");
        return _values[id];
    }
    function push(
        string memory key,
        string memory name,
        uint32 max
    ) public onlyOwner returns (CHK_GameFi_MapItem memory) {
        _length++;
        _values[_length] = CHK_GameFi_MapItem(_length, key, name, max);
        return _values[_length];
    }
    function set(uint16 id, string memory name)
        public
        onlyOwner
        returns (CHK_GameFi_MapItem memory)
    {
        require(id > 0 && id <= _length, "Non-exists map id");
        _values[id].name = name;
        return _values[id];
    }
    function set(
        uint16 id,
        string memory key,
        string memory name
    ) public onlyOwner returns (CHK_GameFi_MapItem memory) {
        require(id > 0 && id <= _length, "Non-exists map id");
        _values[id].key = key;
        _values[id].name = name;
        return _values[id];
    }
    function set(
        uint16 id,
        string memory key,
        string memory name,
        uint32 max
    ) public onlyOwner returns (CHK_GameFi_MapItem memory) {
        require(id > 0 && id <= _length, "Non-exists map id");
        _values[id].key = key;
        _values[id].name = name;
        _values[id].max_units = max;
        return _values[id];
    }
    function pop() public onlyOwner returns (CHK_GameFi_MapItem memory) {
        require(_length > 1, "can not truncate data");
        CHK_GameFi_MapItem memory val = _values[_length];
        delete _values[_length];
        _length--;
        return val;
    }
}