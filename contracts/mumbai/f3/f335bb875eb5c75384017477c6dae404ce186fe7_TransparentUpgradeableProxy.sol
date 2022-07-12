/**
 *Submitted for verification at polygonscan.com on 2022-07-11
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.15;


/*
https://docs.openzeppelin.com/contracts/4.x/api/proxy#TransparentUpgradeableProxy
-----------------------------------------------------------------------------------------
IBeacon ) {BeaconProxy}이(가) 해당 비콘에 대해 예상하는 인터페이스입니다.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/proxy/beacon/IBeacon.sol
-----------------------------------------------------------------------------------------
IERC1822Proxiable ) ERC1822: UUPS(Universal Upgradeable Proxy Standard)는 업그레이드가 현재 구현에 의해 완전히 제어되는 단순화된 프록시를 통한 업그레이드 가능성을 위한 방법을 문서화합니다.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/interfaces/draft-IERC1822.sol
-----------------------------------------------------------------------------------------
Address ) 주소 유형과 관련된 기능의 모음입니다.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/utils/Address.sol
-----------------------------------------------------------------------------------------
StorageSlot ) 특정 저장소 슬롯에 기본 유형을 읽고 쓰기 위한 라이브러리입니다.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/utils/StorageSlot.sol
-----------------------------------------------------------------------------------------
ERC1967Upgrade ) 이 추상 계약은 https://eips.ethereum.org/EIPS/eip-1967[EIP1967] 슬롯에 대한 게터 및 이벤트 발생 업데이트 기능을 제공합니다.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/proxy/ERC1967/ERC1967Upgrade.sol
-----------------------------------------------------------------------------------------
Proxy ) 이 추상 계약은 EVM 명령 'delegate call'을 사용하여 모든 호출을 다른 계약으로 위임하는 폴백 기능을 제공합니다.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/proxy/Proxy.sol
-----------------------------------------------------------------------------------------
ERC1967Proxy ) 이 계약은 업그레이드 가능한 프록시를 구현합니다. 호출을 변경할 수 있는 구현 주소로 위임하므로 업그레이드할 수 있습니다.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/proxy/ERC1967/ERC1967Proxy.sol
-----------------------------------------------------------------------------------------
TransparentUpgradeableProxy ) 이 계약은 관리자가 업그레이드할 수 있는 프록시를 구현합니다.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol
-----------------------------------------------------------------------------------------
*/


interface IBeacon {
    function implementation() external view returns (address);
}

interface IERC1822Proxiable {
    function proxiableUUID() external view returns (bytes32);
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
    function functionCall( address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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

library StorageSlot {
    struct AddressSlot {
        address value;
    }
    struct BooleanSlot {
        bool value;
    }
    struct Bytes32Slot {
        bytes32 value;
    }
    struct Uint256Slot {
        uint256 value;
    }
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

abstract contract ERC1967Upgrade {
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    event Upgraded(address indexed implementation);
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
    function _upgradeToAndCall( address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    event AdminChanged(address previousAdmin, address newAdmin);
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
    event BeaconUpgraded(address indexed beacon);
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

abstract contract Proxy {
    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    function _implementation() internal view virtual returns (address);
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }
    fallback() external payable virtual {
        _fallback();
    }
    receive() external payable virtual {
        _fallback();
    }
    function _beforeFallback() internal virtual {}
}

contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

contract TransparentUpgradeableProxy is ERC1967Proxy {
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

contract testaaa {
    // constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
    //     _changeAdmin(admin_);
    // }
}