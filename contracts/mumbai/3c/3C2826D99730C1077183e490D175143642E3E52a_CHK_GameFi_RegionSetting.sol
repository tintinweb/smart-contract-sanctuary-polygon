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
contract CHK_GameFi_RegionSetting is Ownable, ERC165 {
    struct CHK_GameFi_RegionItem {
        uint16 id;
        uint16 map_id;
        string key;
        string name;
        uint32 max_units;
    }
    uint16 _length;
    mapping(uint16 => CHK_GameFi_RegionItem) _values;
    constructor() {
        _length = 5;
        _values[1] = CHK_GameFi_RegionItem(
            1,
            1,
            "A",
            "Hong Kong Island",
            118222
        );
        _values[2] = CHK_GameFi_RegionItem(2, 1, "B", "Kowloon", 150348);
        _values[3] = CHK_GameFi_RegionItem(3, 1, "C", "Lamma Island", 22954);
        _values[4] = CHK_GameFi_RegionItem(4, 1, "D", "Tsing Yi", 12553);
        _values[5] = CHK_GameFi_RegionItem(
            5,
            1,
            "X",
            "Outlying Islands",
            17754
        );
    }
    function length() public view returns (uint16) {
        return _length;
    }
    function item(uint16 id)
        external
        view
        returns (CHK_GameFi_RegionItem memory)
    {
        require(id > 0 && id <= _length, "Non-exists map id");
        return _values[id];
    }
    function push(
        uint16 map_id,
        string memory key,
        string memory name,
        uint32 max
    ) public onlyOwner returns (CHK_GameFi_RegionItem memory) {
        _length++;
        _values[_length] = CHK_GameFi_RegionItem(
            _length,
            map_id,
            key,
            name,
            max
        );
        return _values[_length];
    }
    function set(uint16 id, string memory name)
        public
        onlyOwner
        returns (CHK_GameFi_RegionItem memory)
    {
        require(id > 0 && id <= _length, "Non-exists map id");
        _values[id].name = name;
        return _values[id];
    }
    function set(
        uint16 id,
        string memory key,
        string memory name
    ) public onlyOwner returns (CHK_GameFi_RegionItem memory) {
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
    ) public onlyOwner returns (CHK_GameFi_RegionItem memory) {
        require(id > 0 && id <= _length, "Non-exists map id");
        _values[id].key = key;
        _values[id].name = name;
        _values[id].max_units = max;
        return _values[id];
    }
    function pop() public onlyOwner returns (CHK_GameFi_RegionItem memory) {
        require(_length > 1, "can not truncate data");
        CHK_GameFi_RegionItem memory val = _values[_length];
        delete _values[_length];
        _length--;
        return val;
    }
}