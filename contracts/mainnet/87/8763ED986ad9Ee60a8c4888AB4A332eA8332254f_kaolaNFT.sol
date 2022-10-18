// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155PresetMinterPauser.sol";

interface TokenLike {
    function transferFrom(address,address,uint) external;
    function transfer(address,uint) external;
    function balanceOf(address) external view  returns (uint);
}

contract kaolaNFT is ERC1155PresetMinterPauser {
    
    uint256                          public n = 6;
    mapping (address => bool)        public permit;
    mapping (address => uint256)     public mintAmount;
    mapping (uint256 => uint256)     public lastTime;
    mapping (address => bool)        public white;
    bool                             public open;
    uint256                          public interval;

    
    constructor() ERC1155PresetMinterPauser( "https://bjsc.space/1155/image/{id}.json") {
            wards[msg.sender] = 1;
    }

    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "kaolaNFT/not-authorized");
        _;
    }
    function file(uint what, uint256 data, address _asset) external auth {
        if (what == 1) {
            permit[_asset] = true;
           mintAmount[_asset] = data;
        }
        if (what == 2) {
            permit[_asset] = false;
        }
        if (what == 3) n = data;
    }
    function setURI(string memory _baseURI) public auth {
         _setURI(_baseURI);      
    }
    
    function _setWhite(address usr) public virtual auth{
        white[usr] = !white[usr];
    }
    function _setOpen() public virtual auth {
        open = !open;
    }
    function _setInterval(uint256 _time) public virtual auth {
        interval = _time;
    }

    function mintAuth(address to, uint256 _tokenid, uint256 amount) public auth {
        _mint(to, _tokenid, amount, "");
    }
    function UserMint(address asset, address to) public returns (uint256) {
        require(permit[asset], "kaolaNFT/The asset has not opened NFT mint");
        TokenLike(asset).transferFrom(msg.sender,address(this),mintAmount[asset]);
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        uint256 _tokenid = uint256(hash)%(10**n);
        _mint(to, _tokenid, 1, "");
        return _tokenid;
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        require(white[to] || white[from] || open || block.timestamp > lastTime[id] + interval, "ERC1155: Not eligible for transfer");
        lastTime[id] = block.timestamp;
        _safeTransferFrom(from, to, id, amount, data);
    } 
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        require(white[to] || white[from] || open , "ERC1155: Not eligible for transfer");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function withdraw(address asses,uint256 wad, address usr) public auth {
        TokenLike(asses).transfer(usr, wad);
    }
    function withdrawNFT(uint256 id, uint256 amount, address usr) public auth {
        safeTransferFrom(address(this),usr,id,amount,"");
    }

}