// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IDeviceManage.sol";

contract DeviceManager is IDeviceManage {

    address public admin; // 管理员
    mapping(address => bool) public Employments; // 是否为员工
    mapping(uint256 => Device) public DeviceData; //设备数据映射表
    uint256 public DeviceCounts; // 设备编号计数器

    constructor() {
        admin = msg.sender;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "DeviceManager: Not valid address");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "DeviceManager: Not admin.");
        _;
    }

    modifier onlyEmployment() {
        require(isEmployment(msg.sender), "DeviceManager: Not employment.");
        _;
    }

    function isEmployment(address employment) public view returns (bool){
        return Employments[employment];
    }

    // 设置员工
    function setEmployment(address employment, bool status) public onlyAdmin {
        bool _status = isEmployment(employment);
        if (status) {
            require(_status == false, "DeviceManager: status no changed.");
        } else {
            require(_status == true, "DeviceManager: status no changed.");
        }
        Employments[employment] = status;
        emit EmploymentEvent(msg.sender, employment, status);
    }

    // 添加设备
    function addDevice(string calldata name, uint256 fee, string calldata content) public onlyEmployment {
        uint256 id = DeviceCounts;
        Device storage device = DeviceData[id];
        device.name = name;
        device.fee = fee;
        device.content = content;
        emit DeviceEvent(id, name, fee, content);
        emit Apply(msg.sender, ManageType.Buy, id, content);
    }

    // 保养设备
    function maintainDevice(uint256 id, string calldata content) public onlyEmployment {
        emit Apply(msg.sender, ManageType.Maintain, id, content);
    }

    // 报废设备
    function scrapDevice(uint256 id, string calldata content) public onlyEmployment {
        emit Apply(msg.sender, ManageType.Scrap, id, content);
    }

    // 添加设备审核
    function auditAddDevice(uint256 id, Status status) public onlyAdmin {
        Device storage device = DeviceData[id];
        device.isAllow = status;
        emit Audit(msg.sender, ManageType.Buy, id, status);
    }

    // 报废设备审核
    function auditScrapDevice(uint256 id, Status status) public onlyAdmin {
        Device storage device = DeviceData[id];
        device.isScrap = status;
        emit Audit(msg.sender, ManageType.Scrap, id, status);
    }

    // 设置员工(批量)
    function BatchSetEmployment(address[] calldata employments, bool status) public onlyAdmin {
        for (uint256 i = 0; i < employments.length; ++i) {
            (bool success,) = address(this).delegatecall(abi.encodeWithSignature("setEmployment(address,bool)", employments[i], status));
            require(success, "DeviceManager: BatchSetEmployment failed.");
        }
    }

    // 添加设备审核(批量)
    function BatchAuditAddDevice(uint256[] calldata ids, Status status) public onlyAdmin {
        for (uint256 i = 0; i < ids.length; ++i) {
            (bool success,) = address(this).delegatecall(abi.encodeWithSignature("auditAddDevice(uint256,Status)", ids[i], status));
            require(success, "DeviceManager: BatchAuditAddDevice failed.");
        }
    }

    // 报废设备审核(批量)
    function BatchAuditScrapDevice(uint256[] calldata ids, Status status) public onlyAdmin {
        for (uint256 i = 0; i < ids.length; ++i) {
            (bool success,) = address(this).delegatecall(abi.encodeWithSignature("auditScrapDevice(uint256,Status)", ids[i], status));
            require(success, "DeviceManager: BatchAuditScrapDevice failed.");
        }
    }

}