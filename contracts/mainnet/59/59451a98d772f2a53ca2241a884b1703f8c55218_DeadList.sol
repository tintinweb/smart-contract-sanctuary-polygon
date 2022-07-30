// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./EllipticCurve.sol";
import "./SVGNFT.sol";

contract Tombstone is ERC721 {
    address immutable owner_;
  
    constructor() ERC721("Tombstone", "tombstone") {
        owner_ = msg.sender;
    }

    function isAddressDead(address dead_address) public view returns (bool) {
        return balanceOf(dead_address) > 0;
    }
  
    function attachTombstone(address dead_address, uint256 private_key) public {
        require(msg.sender == owner_);
        _mint(dead_address, private_key);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal override(ERC721)
    {
        require(from == address(0), "DeadList: Tombstone is immovable");
        super._beforeTokenTransfer(from, to, tokenId);
    }
  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "DeadList: URI get of nonexistent token");
        string memory image = SVGNFT.tombstoneSVG(ownerOf(tokenId), tokenId);
        string memory json = Base64.encode(
        bytes(string(
              abi.encodePacked(
              '{"name": "', "TombStone", '",',
              '"image_data": "', image, '",',
              '"description": "', "The tombstone SBT in 0xDeadList" , '"',
              '}'
              )
          ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}

contract AddressBurier is ERC721 {
    address immutable owner_;
    
    constructor() ERC721("AddressBurier", "burier") {
        owner_ = msg.sender;
    }

    function mintAddressBurier(address send_addr, address dead_address) public {
        require(msg.sender == owner_);
        _mint(send_addr, uint160(dead_address));
    }

    function tokenURI(uint256 tokenId) public override(ERC721) view returns (string memory) {
        require(_exists(tokenId), "DeadList: URI get of nonexistent token");
        string memory image = SVGNFT.burierSVG(address(uint160(tokenId)));
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', "Burier", '",',
                    '"image_data": "', image, '",',
                    '"description": "', "The burier NFT in 0xDeadList" , '"', 
                    '}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}

contract DeadList {  
    Tombstone private immutable tomb_stone_;
    AddressBurier private immutable address_burier_;
    mapping (address => address) private bury_lock_;
    mapping (address => uint256) private expire_time_;

    event Lock(address indexed locker, address indexed locked, uint256 lock_until);

    constructor() {
        tomb_stone_ = new Tombstone();
        address_burier_ = new AddressBurier();
    }
  
    function isAddressDead(address addr) public view returns (bool) {
        return tomb_stone_.isAddressDead(addr);
    }

    function isAddressLocked(address addr) public view returns (bool) {
        return expire_time_[addr] >= block.timestamp;
    }

    function isAddressLockedOrDead(address addr) public view returns (bool) {
        return isAddressDead(addr) || isAddressLocked(addr);
    }

    function getAddressLocker(address addr) public view returns (address, uint256) {
        return (bury_lock_[addr], expire_time_[addr]);
    }

    function validSignature(address lock_address, bytes memory signature, address minter_address, uint256 lock_time, bytes32 block_hash)
      private pure returns (bool) {
        bytes memory data = abi.encodePacked(minter_address, lock_time, block_hash);
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(data.length), data));
        return lock_address == ECDSA.recover(hash, signature);
    }
  
    function lockAddress(address lock_address, bytes memory signature, uint256 lock_time, uint256 block_num) external {
        require(blockhash(block_num) != bytes32(0), "DeadList: invalid block number");
        require(!isAddressDead(lock_address), "DeadList: address already dead");
        require(lock_time >= 1 hours && lock_time <= 48 hours, "DeadList: invalid lock time");
        require(validSignature(lock_address, signature, msg.sender, lock_time, blockhash(block_num)), "DeadList: invalid signature");
        if (!isAddressLocked(lock_address)) {
            bury_lock_[lock_address] = msg.sender;
            expire_time_[lock_address] = block.timestamp + lock_time;
        } else {
            uint256 expire_time = expire_time_[lock_address];
            uint256 new_expire_time = block.timestamp + lock_time;
            expire_time_[lock_address] = new_expire_time > expire_time ? new_expire_time : expire_time;
        }
        emit Lock(bury_lock_[lock_address], lock_address, expire_time_[lock_address]);
    }

    function buryAddress(uint256 private_key) external {
        address dead_address = EllipticCurve.getAddress(private_key);
        require(!isAddressDead(dead_address), "DeadList: address already buried");
        require(isAddressLocked(dead_address), "DeadList: address not locked");
        address_burier_.mintAddressBurier(bury_lock_[dead_address], dead_address);
        tomb_stone_.attachTombstone(dead_address, private_key);
    }
}