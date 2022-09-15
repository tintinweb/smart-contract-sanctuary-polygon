//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Switch this to your own contract address once deployed, for bookkeeping!
// Example Contract Address on Goerli: 0xDBa03676a2fBb6711CB652beF5B7416A53c1421D

contract BuyMeACoffee {
    // Event to emit when a Memo is created.
    // 备忘事件定义，当一个新备忘被创建时触发
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    // Memo struct.
    // 备忘的结构体定义
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    // 合约的部署者，提现资金会到这个地址
    address payable owner;

    // List of all memos received from coffee purchases.
    // 所有购买咖啡的备忘列表
    Memo[] memos;

    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        // 此函数为合约的构造函数，将在合约被部署时调用
        // 设置部署合约的钱包地址为此合约的拥有者
        owner = payable(msg.sender);
    }

    /**
     * @dev fetches all stored memos
     * 获取所有通知列表
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * 给合约的拥有者买一杯咖啡，金额不限
     * @param _name name of the coffee purchaser 购买者的名称
     * @param _message a nice message from the purchaser 购买者的留言信息
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        // Must accept more than 0 ETH for a coffee.
        // 校验金额只要大于 0 就可以
        require(msg.value > 0, "can't buy coffee for free!");

        // Add the memo to storage!
        // 存在购买者的备忘信息
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // Emit a NewMemo event with details about the memo.
        // 触发一个购买通知
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     * 将合约的所有资金转到合约拥有者的钱包地址中
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
     * 挑战1：修改合约的拥有者
     */
    function changeOwner(address payable newOwner) public {
        require(owner == msg.sender, "You are not owner");
        require(newOwner != address(0), "Owner must not be zero address");
        owner = newOwner;
    }

    /**
     * 挑战2: 给合约的拥有者买一大杯咖啡，金额至少 0.003 ETH
     */
    function buyLargeCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value >= 0.003 ether, "min price is 0.003 ether");
        buyCoffee(_name, _message);
    }
}