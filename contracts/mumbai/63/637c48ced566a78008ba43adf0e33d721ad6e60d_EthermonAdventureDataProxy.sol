/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

/**
 *Submitted for verification at polygonscan.com on 2023-03-24
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

library StorageSlot {
    function getAddressSlot(bytes32 slot) internal view returns (address) {
        address impl;
        assembly {
            impl := sload(slot)
        }

        return impl;
    }

    function setAddressSlot(bytes32 slot, address _impl) internal {
        assembly {
            sstore(slot, _impl)
        }
    }
}

contract BasicAccessControl {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

    function initialize() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) external onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function Kill() external onlyOwner {
        selfdestruct(owner);
    }

    function AddModerator(address _newModerator) external onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function RemoveModerator(address _oldModerator) external onlyOwner {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) external onlyOwner {
        isMaintaining = _isMaintaining;
    }
}

// File: contracts/EthermonRevenueProxy.sol

pragma solidity ^0.6.6;

contract EthermonAdventureDataProxy is BasicAccessControl {

    bytes32 public constant IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implemenation")) - 1);

    bytes32 public constant ADMIN_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    // total revenue
    struct LandRevenue {
        uint256 emonAmount;
    }
    struct LandTokenClaim {
        uint256 emonAmount;
    }

    struct ExploreData {
        address sender;
        uint256 typeId;
        uint256 monsterId;
        uint256 siteId;
        uint256 itemSeed;
        uint256 startAt; // blocknumber
    }

    uint256 public exploreCount = 0;
    mapping(uint256 => ExploreData) public exploreData; // explore count => data
    mapping(address => uint256) public explorePending; // address => explore id

    mapping(uint256 => LandTokenClaim) public claimData; // tokenid => claim info
    mapping(uint256 => uint256) public landToken;
    mapping(uint256 => LandRevenue) public siteData; // class id => amount
    mapping(uint256 => uint256[]) public siteClassToken; // class id => token ids

    constructor() public {
        setAdmin(msg.sender);
    }

    function delegate(address _implementation) private {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(
                gas(),
                _implementation,
                0,
                calldatasize(),
                0,
                0
            )

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

    function _fallback() private {
        delegate(getImplementation());
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    modifier onlyAdmin() {
        if (msg.sender == getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    function updateAdmin(address _admin) external onlyAdmin {
        setAdmin(_admin);
    }

    function upgradeTo(address _implementation) external onlyAdmin {
        require(msg.sender == getAdmin(), "not authorized");
        setImplementation(_implementation);
    }

    function getAdmin() private view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT);
    }

    function setAdmin(address _value) private {
        require(_value != address(0), "Invalid Address");
        StorageSlot.setAddressSlot(ADMIN_SLOT, _value);
    }

    function getImplementation() private view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT);
    }

    function setImplementation(address _value) private {
        require(_value != address(0), "Invalid Address");
        StorageSlot.setAddressSlot(IMPLEMENTATION_SLOT, _value);
    }

    function admin() external onlyAdmin returns (address) {
        return getAdmin();
    }

    function implementation() external onlyAdmin returns (address) {
        return getImplementation();
    }
}

// File: contracts/ProxyAdmin.sol

pragma solidity ^0.6.6;

contract ProxyAdmin {
    address public owner;
    bool public isMaintaining = true;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function getProxyAdmin(address _proxy) external view returns (address) {
        (bool success, bytes memory result) = _proxy.staticcall(
            abi.encodeWithSelector(EthermonAdventureDataProxy.admin.selector)
        );
        require(success, "Response failed");
        return abi.decode(result, (address));
    }

    function getProxyImplementation(
        address _proxy
    ) external view returns (address) {
        (bool success, bytes memory result) = _proxy.staticcall(
            abi.encodeWithSelector(
                EthermonAdventureDataProxy.implementation.selector
            )
        );

        require(success, "Response failed");
        return abi.decode(result, (address));
    }

    function updateProxyAdmin(
        address payable _proxy,
        address _admin
    ) external onlyOwner {
        EthermonAdventureDataProxy(_proxy).updateAdmin(_admin);
    }

    function upgrade(
        address payable _proxy,
        address _implementation
    ) external onlyOwner {
        EthermonAdventureDataProxy(_proxy).upgradeTo(_implementation);
    }

    function ChangeOwner(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) public onlyOwner {
        isMaintaining = _isMaintaining;
    }
}