/**
 *Submitted for verification at polygonscan.com on 2022-07-09
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.15;


/*
openzeppelin 계약생성기 ) https://wizard.openzeppelin.com/
설정값 : Burnable,Pausable,Ownable,Transparent
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddressUpgradeable ) 주소 유형과 관련된 함수 모음
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/utils/AddressUpgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Initializable ) 업그레이드 가능한 계약 또는 프록시 뒤에 배치될 모든 종류의 계약을 작성하는 데 도움이 되는 기본 계약
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/proxy/utils/Initializable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ContextUpgradeable ) 트랜잭션의 보낸 사람 및 해당 데이터를 포함하여 현재 실행 컨텍스트에 대한 정보를 제공  
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/utils/ContextUpgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
OwnableUpgradeable ) 특정 기능에 대한 독점적 액세스 권한을 부여할 수 있는 계정(소유자)이 있는 경우 기본 액세스 제어 메커니즘을 제공하는 계약 모듈
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/access/OwnableUpgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IERC20Upgradeable ) EIP에 정의된 ERC20 표준의 인터페이스
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/token/ERC20/IERC20Upgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IERC20MetadataUpgradeable ) ERC20 표준의 선택적 메타데이터 기능을 위한 인터페이스
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ERC20Upgradeable ) {IERC20} 인터페이스 구현
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/token/ERC20/ERC20Upgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ERC20BurnableUpgradeable ) 토큰 소유자가 (이벤트 분석을 통해) 오프 체인(off-chain)으로 인식할 수 있는 방식으로 토큰 소유자가 자신의 토큰과 허용 가능한 토큰을 모두 폐기할 수 있는 {ERC20}의 확장
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PausableUpgradeable ) 인증된 계정에 의해 트리거될 수 있는 비상 중지 메커니즘을 구현할 수 있는 계약 모듈
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/security/PausableUpgradeable.sol
*/



library AddressUpgradeable {
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;
    event Initialized(uint8 version);
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }
    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }
    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    uint256[49] private __gap;
}

contract ERC20Upgradeable is Initializable, ContextUpgradeable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    string private _name;
    string private _symbol;
    struct _test1_struct {
        uint128 _test1;
    }
    mapping(address => _test1_struct) private _test1_mapping;

    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view  returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }



    // ---------------------------------------------------------
    function _test1_set(address _ars,uint128 set_) public {
        _test1_mapping[_ars]._test1 = set_;
    }
    function _test1_get(address _ars) public view returns (uint128) {
        return  _test1_mapping[_ars]._test1;
    }






    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from,address to, uint256 amount) internal virtual {}
    uint256[45] private __gap;

}

abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }
    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }
    modifier whenPaused() {
        _requirePaused();
        _;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}
contract ProjectToken1 is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable {
    function initialize() initializer public {
        __ERC20_init("MyToken", "MTK");
        __Pausable_init();
        __Ownable_init();
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }
}