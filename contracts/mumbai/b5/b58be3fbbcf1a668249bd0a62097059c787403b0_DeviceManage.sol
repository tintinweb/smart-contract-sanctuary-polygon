// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IDeviceManage.sol";

contract DeviceManage is IDeviceManage {

    address public admin; // 管理员
    mapping(address => bool) public Employments; // 是否为员工
    mapping(uint256 => Device) public DeviceData; //设备数据映射表
    mapping(uint256 => uint256) public ApplicationToDevice; //设备数据映射表
    uint256 public DeviceCounts; // 设备编号计数器
    uint256 public DeviceApplicationCounts; // 设备申请记录计数器
    mapping(uint256 => bool) public ScrapLock; // 报废申请锁

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

    modifier deviceAvailable(uint256 deviceId) {
        Device memory device = DeviceData[deviceId];
        require(device.isAllow, "DeviceManager: Not yet purchase.");
        require(!device.isScrap, "DeviceManager: Have been scrapped.");
        _;
    }

    modifier scrapLocked(uint256 deviceId) {
        require(!ScrapLock[deviceId], "DeviceManager: device is scrapLocked.");
        _;
    }

    function isEmployment(address employment) public view returns (bool){
        return Employments[employment];
    }

    // 设置管理员
    function setAdmin(address _address) public onlyAdmin validAddress(_address) {
        admin = _address;
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
        uint256 deviceId = ++DeviceCounts;
        uint256 applicationId = ++DeviceApplicationCounts;
        Device storage device = DeviceData[deviceId];
        device.name = name;
        device.fee = fee;
        device.content = content;

        ApplicationToDevice[applicationId] = deviceId;

        emit DeviceEvent(deviceId, name, fee, content);
        emit Apply(applicationId, deviceId, msg.sender, ManageType.Buy, content);
    }

    // 保养设备
    function maintainDevice(uint256 id, string calldata content) public onlyEmployment deviceAvailable(id) scrapLocked(id) {
        emit Apply(++DeviceApplicationCounts, id, msg.sender, ManageType.Maintain, content);
    }

    // 报废设备
    function scrapDevice(uint256 id, string calldata content) public onlyEmployment deviceAvailable(id) scrapLocked(id) {
        ScrapLock[id] = true;
        emit Apply(++DeviceApplicationCounts, id, msg.sender, ManageType.Scrap, content);
    }

    // 添加设备审核
    function auditAddDevice(uint256 id, bool status) public onlyAdmin {

        uint256 deviceId = ApplicationToDevice[id];
        Device storage device = DeviceData[deviceId];
        require(!device.isAllow, "DeviceManager: Have been purchased.");

        device.isAllow = status;
        emit Audit(id, msg.sender, ManageType.Buy, status);
    }

    // 报废设备审核
    function auditScrapDevice(uint256 id, bool status) public onlyAdmin {

        uint256 deviceId = ApplicationToDevice[id];
        Device storage device = DeviceData[deviceId];
        require(!device.isScrap, "DeviceManager: Have been scrapped.");

        device.isScrap = status;
        if (!status) {
            ScrapLock[id] = false;
        }
        emit Audit(id, msg.sender, ManageType.Scrap, status);
    }

    // 设置员工(批量)
    function BatchSetEmployment(address[] calldata employments, bool status) public onlyAdmin {
        for (uint256 i = 0; i < employments.length; ++i) {
            (bool success,) = address(this).delegatecall(abi.encodeWithSignature("setEmployment(address,bool)", employments[i], status));
            require(success, "DeviceManager: BatchSetEmployment failed.");
        }
    }

    // 添加设备审核(批量)
    function BatchAuditAddDevice(uint256[] calldata ids, bool status) public onlyAdmin {
        for (uint256 i = 0; i < ids.length; ++i) {
            (bool success,) = address(this).delegatecall(abi.encodeWithSignature("auditAddDevice(uint256,bool)", ids[i], status));
            require(success, "DeviceManager: BatchAuditAddDevice failed.");
        }
    }

    // 报废设备审核(批量)
    function BatchAuditScrapDevice(uint256[] calldata ids, bool status) public onlyAdmin {
        for (uint256 i = 0; i < ids.length; ++i) {
            (bool success,) = address(this).delegatecall(abi.encodeWithSignature("auditScrapDevice(uint256,bool)", ids[i], status));
            require(success, "DeviceManager: BatchAuditScrapDevice failed.");
        }
    }

}