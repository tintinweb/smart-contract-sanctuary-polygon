// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

interface IERC721Interface {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract DegenDefiAddresses {
    struct AddrStruct {
        address addr1;
        address addr2;
        address addr3;
    }
    address public owner;

    IERC721Interface token =
        IERC721Interface(0x7f760C16d3444dC90E04B8249E839e92a44e9F4e);

    mapping(address => uint256) addressMap;
    mapping(address => bool) blacklistMap;

    AddrStruct[] private allAddresses;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can call this function");
        _;
    }

    modifier notBlacklisted(address addr) {
        require(blacklistMap[addr] == false, "Wallet is Blacklisted");
        _;
    }

    modifier nftOwner() {
        require(token.balanceOf(msg.sender) > 0, "User does not own the NFT");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function blacklistWallet(address addr) public onlyOwner {
        blacklistMap[addr] = true;
    }

    function blacklistWipe(address addr) public onlyOwner {
        blacklistMap[addr] = false;
    }

    function getIndex() public view returns (uint256 index) {
        return addressMap[msg.sender];
    }

    function getIndexForWallet(
        address wallet
    ) public view returns (uint256 index) {
        return addressMap[wallet];
    }

    function addAddresses(
        address addr1,
        address addr2
    ) external notBlacklisted(msg.sender) nftOwner {
        _addAddresses(msg.sender, addr1, addr2);
    }

    function _addAddresses(
        address wallet,
        address addr1,
        address addr2
    ) internal {
        uint256 index = getIndexForWallet(wallet);
        require(index == 0, "Address already exists - use update instead");

        uint256 aryLen = allAddresses.length + 1;
        AddrStruct memory newStruct = AddrStruct(wallet, addr1, addr2);
        allAddresses.push(newStruct);
        addressMap[wallet] = aryLen;
    }

    function updateAddress(
        address addr,
        uint256 addrNum
    ) external notBlacklisted(msg.sender) {
        _updateAddress(msg.sender, addr, addrNum);
    }

    function _updateAddress(
        address wallet,
        address addr,
        uint256 addrNum
    ) internal {
        uint256 index = getIndexForWallet(wallet);
        require(index != 0, "Address has not been added yet");
        require(addrNum > 0 && addrNum < 3, "Number can't be greater than 2");
        AddrStruct storage item = allAddresses[index - 1];
        if (addrNum == 1) item.addr2 = addr;
        else item.addr3 = addr;
    }

    function updateAllAddresses(
        address addr1,
        address addr2
    ) external notBlacklisted(msg.sender) {
        _updateAllAddresses(msg.sender, addr1, addr2);
    }

    function _updateAllAddresses(
        address wallet,
        address addr1,
        address addr2
    ) internal {
        uint256 index = getIndexForWallet(wallet);
        require(index != 0, "Address has not been added yet");
        AddrStruct storage item = allAddresses[index - 1];
        item.addr1 = wallet;
        item.addr2 = addr1;
        item.addr3 = addr2;
    }

    function getMyAddresses()
        public
        view
        notBlacklisted(msg.sender)
        returns (address addr1, address addr2, address addr3)
    {
        uint256 index;
        require((index = getIndex()) != 0, "No Addresses for this wallet");
        AddrStruct memory item = allAddresses[index - 1];
        return (item.addr1, item.addr2, item.addr3);
    }

    function getAddressesForWallet(
        address wallet
    )
        public
        view
        notBlacklisted(wallet)
        returns (address addr1, address addr2, address addr3)
    {
        uint256 index;
        require(
            (index = getIndexForWallet(wallet)) != 0,
            "No Addresses for this wallet"
        );
        AddrStruct memory item = allAddresses[index - 1];
        return (item.addr1, item.addr2, item.addr3);
    }

    function ownerUpdateAllAddresses(
        address wallet,
        address addr1,
        address addr2
    ) external onlyOwner {
        require(
            blacklistMap[wallet] == false,
            "Wallet is Blacklisted - You need to unblacklist first"
        );
        _updateAllAddresses(wallet, addr1, addr2);
    }

    function ownerAddAddresses(
        address wallet,
        address addr1,
        address addr2
    ) external onlyOwner {
        require(
            blacklistMap[wallet] == false,
            "Wallet is Blacklisted - You need to unblacklist first"
        );
        _addAddresses(wallet, addr1, addr2);
    }

    function showAllAddresses()
        external
        view
        onlyOwner
        returns (AddrStruct[] memory)
    {
        return allAddresses;
    }

    function getAddressesLength()
        external
        view
        onlyOwner
        returns (uint256 length)
    {
        return allAddresses.length;
    }

    function getItemAtIndex(
        uint256 index
    ) external view onlyOwner returns (AddrStruct memory) {
        require(index < allAddresses.length, "Index larger than Array");
        return allAddresses[index];
    }
}