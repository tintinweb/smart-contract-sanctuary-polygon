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

    IERC721Interface public token =
        IERC721Interface(0x7f760C16d3444dC90E04B8249E839e92a44e9F4e);

    mapping(address => uint256) addressMap;
    mapping(address => bool) blacklistMap;

    AddrStruct[] private allAddresses;

    // Modifiers here
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

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Owner functions
    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function changeNftContract(address nftContract) external onlyOwner {
        token = IERC721Interface(nftContract);
    }

    function blacklistWallet(address addr) public onlyOwner {
        blacklistMap[addr] = true;
    }

    function blacklistWipe(address addr) public onlyOwner {
        blacklistMap[addr] = false;
    }

    function ownerUpdateAddresses(
        address wallet,
        address addr1,
        address addr2
    ) external onlyOwner {
        require(
            blacklistMap[wallet] == false,
            "Wallet is Blacklisted - You need to unblacklist first"
        );
        _updateAddresses(wallet, addr1, addr2);
    }

    // Public functions
    function getIndex(address wallet) public view returns (uint256 index) {
        return addressMap[wallet];
    }

    // Write functions
    function updateAddress(
        address addr,
        uint256 addrNum
    ) external notBlacklisted(msg.sender) nftOwner {
        _updateAddress(msg.sender, addr, addrNum);
    }

    function _updateAddress(
        address wallet,
        address addr,
        uint256 addrNum
    ) internal {
        uint256 index = getIndex(wallet);
        require(index != 0, "Address has not been added yet");
        require(addrNum > 0 && addrNum < 3, "Number can't be greater than 2");
        AddrStruct storage item = allAddresses[index - 1];
        if (addrNum == 1) item.addr2 = addr;
        else item.addr3 = addr;
    }

    function updateAddresses(
        address addr1,
        address addr2
    ) external notBlacklisted(msg.sender) {
        _updateAddresses(msg.sender, addr1, addr2);
    }

    function _updateAddresses(
        address wallet,
        address addr1,
        address addr2
    ) internal {
        uint256 index = getIndex(wallet);
        // if 0 means it doesn't yet exist so we create a new one and add it to the array
        // otherwise we will update the existing one.
        if (index == 0) {
            uint256 aryLen = allAddresses.length + 1;
            AddrStruct memory newStruct = AddrStruct(wallet, addr1, addr2);
            allAddresses.push(newStruct);
            addressMap[wallet] = aryLen;
        } else {
            AddrStruct storage item = allAddresses[index - 1];
            item.addr1 = wallet;
            item.addr2 = addr1;
            item.addr3 = addr2;
        }
    }

    // Read functions
    function getAddresses(
        address wallet
    )
        public
        view
        notBlacklisted(wallet)
        returns (address addr1, address addr2, address addr3)
    {
        uint256 index = getIndex(wallet);
        if (index == 0) {
            return (wallet, address(0), address(0));
        }
        AddrStruct memory item = allAddresses[index - 1];
        return (item.addr1, item.addr2, item.addr3);
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
        require(
            index > 0 && index <= allAddresses.length,
            "Index larger than Array"
        );
        return allAddresses[index - 1];
    }
}