// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
}


library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }
            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e003");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e004");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e005");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e006");
        uint256 c = a / b;
        return c;
    }
}

interface IPair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface sharePlus {
    function setShare() external;
}


interface HIMK001 {

    function setConfigAddress(address _marketAddress, address _shareAddress) external;

    function setFee(uint256 _marketRate, uint256 _shareRate) external;

    function setMinAddPoolAmount(uint256 _minAddPoolAmount) external;

    function setWhiteListSet(address[] memory _addressList, bool _status) external;

    function addPairAddressList(address[] calldata _pairAddressList) external;

    function removePairAddressList(address[] calldata _pairAddressList) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


}

contract HIMK002 is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public whiteListSet;
    address public marketAddress;
    address public shareAddress;
    EnumerableSet.AddressSet private pairAddressList;
    uint256 private _totalSupply;
    uint256 public marketRate = 19;
    uint256 public shareRate = 30;
    uint256 public minAddPoolAmount = 1 * (10 ** 4) * (10 ** 18);
    string private _name;
    string private _symbol;
    uint256 private _decimals;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event addPairEvent(address _txOrigin, address _msgSender, address _pair, uint256 _time);
    event transferType(string _type, address sender, address recipient, uint256 amount);

    address public childAddress;

    constructor (
        address newOwner_,
        string memory name_,
        string memory symbol_,
        uint256 decimals_,
        uint256 totalSupply_
    )  {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_.mul(10 ** _decimals);
        _balances[newOwner_] = _totalSupply;
        whiteListSet[address(this)] = true;
        whiteListSet[msg.sender] = true;
        emit Transfer(address(0), newOwner_, _totalSupply);
    }

    function _getRevertMsg(bool success, bytes memory result) private pure {
        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    function setChildAddress(address _childAddress) external onlyOwner {
        childAddress = _childAddress;
    }

    function setConfigAddress(address _marketAddress, address _shareAddress) external onlyOwner {
        (bool success,bytes memory result) = childAddress.delegatecall(abi.encodeWithSelector(HIMK001.setConfigAddress.selector, _marketAddress, _shareAddress));
        _getRevertMsg(success, result);
    }

    function setFee(uint256 _marketRate, uint256 _shareRate) public onlyOwner {
        (bool success,bytes memory result) = childAddress.delegatecall(abi.encodeWithSelector(HIMK001.setFee.selector, _marketRate, _shareRate));
        _getRevertMsg(success, result);
    }

    function setMinAddPoolAmount(uint256 _minAddPoolAmount) public onlyOwner {
        (bool success,bytes memory result) = childAddress.delegatecall(abi.encodeWithSelector(HIMK001.setMinAddPoolAmount.selector, _minAddPoolAmount));
        _getRevertMsg(success, result);
    }

    function setWhiteListSet(address[] memory _addressList, bool _status) external onlyOwner {
        (bool success,bytes memory result) = childAddress.delegatecall(abi.encodeWithSelector(HIMK001.setWhiteListSet.selector, _addressList, _status));
        _getRevertMsg(success, result);
    }

    function addPairAddressList(address[] calldata _pairAddressList) external onlyOwner {
        (bool success,bytes memory result) = childAddress.delegatecall(abi.encodeWithSelector(HIMK001.addPairAddressList.selector, _pairAddressList));
        _getRevertMsg(success, result);
    }

    function removePairAddressList(address[] calldata _pairAddressList) external onlyOwner {
        (bool success,bytes memory result) = childAddress.delegatecall(abi.encodeWithSelector(HIMK001.removePairAddressList.selector, _pairAddressList));
        _getRevertMsg(success, result);
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        (bool success,bytes memory result) = childAddress.delegatecall(abi.encodeWithSelector(HIMK001.transfer.selector, recipient, amount));
        _getRevertMsg(success, result);
        return success;
    }


    function approve(address spender, uint256 amount) public virtual returns (bool) {
        (bool success,bytes memory result) = childAddress.delegatecall(abi.encodeWithSelector(HIMK001.approve.selector, spender, amount));
        _getRevertMsg(success, result);
        return success;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        (bool success,bytes memory result) = childAddress.delegatecall(abi.encodeWithSelector(HIMK001.transferFrom.selector, sender, recipient, amount));
        _getRevertMsg(success, result);
        return success;
    }

    function getPairAddressList() external view returns (address[] memory) {
        return pairAddressList.values();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
}