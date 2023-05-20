// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IPet.sol";

contract Pet is IPet {
    mapping(uint256 => address) public Owners; // 宠物主人
    mapping(uint256 => Agreement) public Agreements; // 协议
    mapping(address => uint256) public Allowance; // 可提款额度
    mapping(address => bool) public Shelters; // 救助站
    uint256 public PetCounts; // 宠物数量
    uint256 public AgreementCounts; // 协议数量
    address public admin; // 管理员地址
    bool public locked; // 合约是否锁定

    constructor() {
        admin = msg.sender;
    }

    modifier noReEntrant() {
        require(!locked, "Pet: No re-entrant");
        locked = true;
        _;
        locked = false;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Pet: Not valid address");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Pet: Not admin.");
        _;
    }

    modifier onlyShelter() {
        require(isShelter(msg.sender), "Pet: Not shelter.");
        _;
    }

    modifier onlyOwner(uint256 id) {
        require(ownerOf(id) == msg.sender, "Pet: Not owner.");
        _;
    }

    function isShelter(
        address shelter // 判定地址
    ) public view returns (bool){
        return Shelters[shelter];
    }

    function ownerOf(
        uint256 id // 宠物编号
    ) public view returns (address){
        return Owners[id];
    }

    function setShelter(
        address shelter, // 账号地址
        bool status // 认证或者移除
    ) public onlyAdmin {
        // 判断账户地址是否为救助站
        bool _status = isShelter(shelter);
        // 如果状态不改变，状态回滚
        if (status) {
            require(_status == false, "Pet: status no changed.");
        } else {
            require(_status == true, "Pet: status no changed.");
        }
        // 更改状态
        Shelters[shelter] = status;
        // 调用ShelterEvent事件
        emit ShelterEvent(msg.sender, shelter, status);
    }

    function addPet(
        address to, // 预定宠物主人地址
        Pet calldata pet // 宠物数据
    ) public onlyShelter validAddress(to) {
        // 读取宠物数量
        uint256 id = PetCounts;
        // 将to地址址设置为宠物主人
        Owners[id] = to;
        // 宠物编号递增
        ++PetCounts;
        // 调用Transfer事件
        emit Transfer(msg.sender, address(0), to, id, TransferType.Register);
        // 调用PetURI事件
        emit PetURI(id, pet);
    }

    function setPetURI(
        uint256 id, // 宠物编号
        Pet calldata pet // 宠物新的数据
    ) public onlyOwner(id) {
        // 调用PetURI事件
        emit PetURI(id, pet);
    }

    function setPeopleURI(
        People calldata people // 用户新的数据
    ) public {
        // 调用PeopleURI事件
        emit PeopleURI(msg.sender, people);
    }

    function transferFrom(
        address from, // 宠物主人
        address to, // 新的宠物主人
        uint256 id, // 宠物编号
        TransferType transferType// 变更类型
    ) public onlyShelter {
        // 调用_transferFrom方法
        _transferFrom(msg.sender, from, to, id, transferType);
    }

    function _transferFrom(
        address operator, // 操作人
        address from, // 宠物主人
        address to, // 新的宠物主人
        uint256 id, // 宠物编号
        TransferType transferType // 变更类型
    ) private validAddress(to) {
        // 限制条件： from地址必须是宠物主人
        require(this.ownerOf(id) == from, "Pet: transfer from incorrect owner");
        // 更新宠物主人
        Owners[id] = to;
        // 调用Transfer事件
        emit Transfer(operator, from, to, id, transferType);
    }

    function generateAgreement(
        address counterParty, // 协议对手方
        uint256 petId, // 宠物编号
        uint256 fee, // 领养费用
        string calldata URI // 协议元数据
    ) public onlyOwner(petId) onlyShelter {
        // 读取协议数量
        uint256 id = AgreementCounts;
        // 实例化Agreement
        Agreement storage agreement = Agreements[id];
        // 交易对手方A：救助站
        agreement.partyA = msg.sender;
        // 交易对手方B：领养用户
        agreement.partyB = counterParty;
        // 宠物编号
        agreement.petId = petId;
        // 领养费用
        agreement.fee = fee;
        // 协议编号递增
        ++AgreementCounts;
        // 调用GenerateAgreement事件
        emit GenerateAgreement(id, agreement, URI);
    }

    function signAgreement(
        uint256 id // 协议编号
    ) public payable {
        // 根据编号读取协议数据
        Agreement storage agreement = Agreements[id];
        // 检查合同状态
        // 限制条件：调用人必须是协议中的对手方B
        // 限制条件：需要保证对手方B未签署协议
        // 限制条件：往合约发送的以太币数量必须等于协议中的领养费用
        require(agreement.partyB == msg.sender, "Pet: Invalid party.");
        require(!agreement.signedByPartyB, "Pet: Already signed.");
        require(agreement.fee == msg.value, " Pet: Invalid fee.");
        // 修改对手方B签署状态
        agreement.signedByPartyB = true;
        // 修改救助站提款额度
        Allowance[agreement.partyA] += msg.value;
        // 调用_transferFrom函数
        _transferFrom(
            agreement.partyA,
            agreement.partyA,
            agreement.partyB,
            agreement.petId,
            TransferType.Adopt
        );
        // 调用SignAgreement事件
        emit SignAgreement(id, agreement);
    }

    function petDaily(
        uint256 id, // 宠物编号
        string calldata URI //宠物照片元数据
    ) public onlyOwner(id) {
        // 调用PetDaily事件
        emit PetDaily(msg.sender, id, URI);
    }

    function withdraw() public noReEntrant {
        // 状态变量进行缓存
        uint256 bal = Allowance[msg.sender];
        // 限制条件：可提款额度必须大于0
        require(bal > 0, "Pet: Empty allowance.");
        // 提款交易
        (bool sent,) = msg.sender.call{value : bal}("");
        // 限制条件：交易失败回滚
        require(sent, "Pet: Failed to send Ether.");
        // 修改可提款额度
        Allowance[msg.sender] = 0;
    }

    receive() external payable {} // 合约实现receive函数来接收以太币
}