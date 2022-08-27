/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IAnycallV6Proxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function executor() external view returns (address);
}

interface IExecutor {
    function context() external returns (address from, uint256 fromChainID, uint256 nonce);
}

contract Administrable {
    address public admin;
    address public pendingAdmin;
    event LogSetAdmin(address admin);
    event LogTransferAdmin(address oldadmin, address newadmin);
    event LogAcceptAdmin(address admin);

    function setAdmin(address admin_) internal {
        admin = admin_;
        emit LogSetAdmin(admin_);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = pendingAdmin;
        pendingAdmin = newAdmin;
        emit LogTransferAdmin(oldAdmin, newAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit LogAcceptAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}

abstract contract AnyCallReceiver is Administrable {
    uint256 public flag; // 0: pay on dest chain, 2: pay on source chain
    address public anyCallProxy;

    mapping(uint256 => address) public sender;

    modifier onlyExecutor() {
        require(msg.sender == IAnycallV6Proxy(anyCallProxy).executor());
        _;
    }

    constructor (address anyCallProxy_, uint256 flag_) {
        setAdmin(msg.sender);
        anyCallProxy = anyCallProxy_;
        flag = flag_;
    }

    function setSenders(uint256[] memory chainIDs, address[] memory  senders) public onlyAdmin {
        for (uint i = 0; i < chainIDs.length; i++) {
            sender[chainIDs[i]] = senders[i];
        }
    }

    function setAnyCallProxy(address proxy) public onlyAdmin {
        anyCallProxy = proxy;
    }

    function onReceive(uint256 fromChainID, bytes calldata data) internal virtual returns (bool success, bytes memory result);

    function anyExecute(bytes calldata data) external onlyExecutor returns (bool success, bytes memory result) {
        (address callFrom, uint256 fromChainID,) = IExecutor(IAnycallV6Proxy(anyCallProxy).executor()).context();
        require(sender[fromChainID] == callFrom, "call not allowed");
        onReceive(fromChainID, data);
    }
}

interface IMultiHonor {
    function setVEPower(uint256[] calldata ids, uint256[] calldata vePower) external;
    function VEPower(uint256 tokenId) view external returns(uint256);
}

contract VEPowerOracleReceiver is AnyCallReceiver {
    address public multiHonor;
    uint256 public veEpochLength = 7257600; // 12 weeks
    mapping(uint256 => uint256) public delegatedPower; // ve key => power

    constructor (address anyCallProxy_, uint256 flag_, address multiHonor_) AnyCallReceiver(anyCallProxy_, flag_) {
        multiHonor = multiHonor_;
    }

    function currentEpoch() public view returns (uint256) {
        return block.timestamp / veEpochLength;
    }

    function veKey(uint256 fromChainID, uint256 ve_id, uint256 epoch) public pure returns (uint256) {
        // fromChainID 1, ve_id 2, epoch 3 => veKey 0x100000000000000020000000000000003
        return (fromChainID << 128) + (ve_id << 64) + epoch;
    }

    /// @notice onReceive decode anyCall msg, update dao user's ve power
    function onReceive(uint256 fromChainID, bytes calldata data) internal override returns (bool success, bytes memory result) {
        (uint256 ve_id, uint256 dao_id, uint256 power) = abi.decode(
            data,
            (uint256, uint256, uint256)
        );

        uint256 _veKey = veKey(fromChainID, ve_id, currentEpoch());

        uint256 oldPower = IMultiHonor(multiHonor).VEPower(dao_id);
        uint256 newPower = oldPower - delegatedPower[_veKey] + power;

        uint256[] memory ids = new uint256[](1);
        ids[0] = dao_id;
        uint256[] memory vePowers = new uint256[](1);
        vePowers[0] = newPower;
    
        IMultiHonor(multiHonor).setVEPower(ids, vePowers);
    }
}