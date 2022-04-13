// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;
import "./Ownable.sol";

contract FountainTokenInterface is Ownable {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
    function balanceOf(address owner) public view returns (uint256) {}
    function getStatus() public view returns (uint256[] memory) {}
}

contract EGGAuth is Ownable {
    struct User {
        string email;
        bool isBind;
    }
    mapping(address => bool) private blacklist;
    mapping(address => User) private emails;
    bool private isLock = false;
    FountainTokenInterface fountain =
        FountainTokenInterface(0x552bFb1A18BF5a7B70Bb1B786Af33cebD5Dd537F);

    function getAllOwnerTokens(address addr)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory baseData = fountain.getStatus();
        uint256 mintedSupply = baseData[3];
        uint256 count = fountain.balanceOf(addr);
        uint256[] memory tokens = new uint256[](count);
        uint256 pushed = 0;
        for (uint256 i = 1; i < mintedSupply + 1; i++) {
            if (fountain.ownerOf(i) == addr) {
                tokens[pushed] = i;
                pushed++;
            }
        }
        return tokens;
    }
    
    function checkAllAddrEmail(address[] memory addrs) public view returns(uint256[] memory){
        uint256[] memory list = new uint256[](addrs.length);
        for(uint256 i = 0 ; i < addrs.length; i ++){
            list[i] = fountain.balanceOf(addrs[i]);
        }
        return list;
    }
    function setLock(bool _islock) public virtual onlyOwner {
        isLock = _islock;
    }
    function bindEmail(string memory _email) public virtual {
        if(isLock){
            require(!blacklist[msg.sender], "you are in balcklist");
            require(fountain.balanceOf(msg.sender) > 0, "not balance");
        }
        emails[msg.sender].isBind = true;
        emails[msg.sender].email = _email;
    }

    function getAddrEmail(address addr) public view returns (string memory) {
        return emails[addr].email;
    }

    function checkBinkEmail(address addr) public view returns (bool) {
        return emails[addr].isBind;
    }

    function setBacklist(address addr, bool status) public virtual onlyOwner {
        blacklist[addr] = status;
    }

    function login(address addr) public view returns (uint256[] memory tokens){
        if(blacklist[addr]){
            return new uint256[](0);
        }else{
            return getAllOwnerTokens(addr);
        }
    }
}