/**
 *Submitted for verification at polygonscan.com on 2022-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant tableEncode = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant tableDecode = hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000003e0000003f3435363738393a3b3c3d00000000000000000102030405060708090a0b0c0d0e0f101112131415161718190000000000001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f3031323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    bytes1 internal constant padding = '=';
    function encode(bytes calldata data) public pure returns(bytes memory) {
        bytes memory output;
        uint256 i;
        uint256 j;
        uint256 k;
        output = new bytes(((data.length + 2) / 3) * 4);
        unchecked {
            i = 0;
            j = 0;
            k = (data.length / 3) * 3;
            while(i < k) {
                output[j] = tableEncode[uint256(uint8(data[i])) >> 2];
                j++;
                output[j] = tableEncode[((uint256(uint8(data[i])) & 0x03) << 4) | (uint256(uint8(data[i + 1])) >> 4)];
                i++;
                j++;
                output[j] = tableEncode[((uint256(uint8(data[i])) & 0x0f) << 2) | (uint256(uint8(data[i + 1])) >> 6)];
                i++;
                j++;
                output[j] = tableEncode[uint256(uint8(data[i])) & 0x3f];
                i++;
                j++;
            }
            if(i + 1 <= data.length) {
                output[j] = tableEncode[uint256(uint8(data[i])) >> 2];
                j++;
                if(i + 2 <= data.length) {
                    output[j] = tableEncode[((uint256(uint8(data[i])) & 0x03) << 4) | (uint256(uint8(data[i + 1])) >> 4)];
                    i++;
                    j++;
                    output[j] = tableEncode[((uint256(uint8(data[i])) & 0x0f) << 2)];
                }
                else {
                    output[j] = tableEncode[((uint256(uint8(data[i])) & 0x03) << 4)];
                    j++;
                    output[j] = padding;
                }
                j++;
                output[j] = padding;
            }
        }
        return output;
    }
    function decode(bytes calldata data) public pure returns(bytes memory) {
        uint256 length;
        bytes memory output;
        uint256 i;
        uint256 j;
        uint256 k;
        length = (data.length / 4) * 3;
        if(data.length >= 4) {
            if(data[data.length - 1] == padding) {
                length--;
                if(data[data.length - 2] == padding) {
                    length--;
                }
            }
        }
        output = new bytes(length);
        unchecked {
            i = 0;
            j = 0;
            k = (length / 3) * 3;
            while(i < k) {
                output[i] = (tableDecode[uint256(uint8(data[j]))] << 2) | (tableDecode[uint256(uint8(data[j + 1]))] >> 4);
                i++;
                j++;
                output[i] = (tableDecode[uint256(uint8(data[j]))] << 4) | (tableDecode[uint256(uint8(data[j + 1]))] >> 2);
                i++;
                j++;
                output[i] = (tableDecode[uint256(uint8(data[j]))] << 6) | tableDecode[uint256(uint8(data[j + 1]))];
                i++;
                j += 2;
            }
            if(i + 1 <= length) {
                output[i] = (tableDecode[uint256(uint8(data[j]))] << 2) | (tableDecode[uint256(uint8(data[j + 1]))] >> 4);
                if(i + 2 <= length) {
                    i++;
                    j++;
                    output[i] = (tableDecode[uint256(uint8(data[j]))] << 4) | (tableDecode[uint256(uint8(data[j + 1]))] >> 2);
                }
            }
        }
        return output;
    }
    function encode(string calldata data) public pure returns(string memory) {
        return string(encode(bytes(data)));
    }
    function decode(string calldata data) public pure returns(string memory) {
        return string(decode(bytes(data)));
    }
}

interface IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external returns(bytes4);
}

contract Erc721 {
    bytes internal constant png = hex"89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7AF40000000467414D410000B18F0BFC6105000000206348524D00007A26000080840000FA00000080E8000075300000EA6000003A98000017709CBA513C000000097048597300000EC400000EC401952B0E1B000002EC494441545847B596C1959D300C452985525C0AA5B8141639A9C3EBD4900525649F05D1952D1046E6CFFF67C29937605BD27B92E50FD3BECBDF03B645903BC85C640B6EB62FEC270CA205C356BA6006990FED23C16B6C0B54C09342700B0806416F029EAA25495401CD70DB6243106516DA753643A1C245CC5300806454DA6E2BA6A922CDD39E655C9A9FB779CCBE257415D09C86AA65BDA0BA91475041E9459C460EEE020C81737E411E2189985562D9F67A723016D060E4641611BC0362F4F1257A1B74CA3CA2609F82CA5E625B862A84451322CFEB07257F05621A399C1701063AFE3B4A1E819EF0C75DFE9F83633270FC0EACEB8F7DFFFB4704E493CB13A32C72FC0EE42CA442CE557E9783F32260F90F7B0EC8BC94A24084DE1B673D867A4EF3E1905252271FE4531829976D0173CA4BC2D691299D02AC5CF39C2EC1DEC5B2E44ACA25F12CEE6A02042AA0A8802BD91339B6B6CE3DB2AD6596FD6E1560DF11C0FD2E6049BAD80719C182DAB817A099723562EC4DC0BA8A00A9CAB6A653C0DA04F45518013BCA6B635F0D233CF69B8CE5D9EEB5D985BCE4F37B20370134A3057D17888204522EAD425FFA95CA50219ABC3E4F9C7D1495927482E755CAC33B3E221AE110C025C446AAD58090B1640D076F47158800FE7102B6AD0A401D770302BF2A06F17A9900C8051B02E4C821A21E79D92EE124BE0A98E73A88A00E22C0EE7C6CCC829EBCBEF745802FFB2180461781F9EC7EE2117FE2532A12A09F60EECDA590B1B7E103859716604C69558090027E59ADECF82769DC3E9EF6802A77812F46CED8DB5CEC5A36C4FAF9AB099026D3B2CBB1337B12653B7C5C59E9028A933738E624F8C5D6B606340100424430AF655F4E01EAD75556666B809018302F4E3E88FA787BB7CEF1D233DED6B4ECBD78199BFFF12E083122F7D9838B008EF4D96C9C303BE23D88FF2CC095B677BCD8B90C6944FF5BAF107BEFEF31163022EFB3EF8273AAB2F4C1C5A6C1DB196201037270CB3EC84E7FD8BA6E5704DB7917F044DE670F0201F4C1D76CA7FD1F877DDE4345BABB2D0000000049454E44AE426082";
    address internal immutable self;
    mapping(address => bool) internal owners;
    mapping(uint256 => address) internal _owner;
    mapping(address => uint256) internal _balance;
    mapping(uint256 => address) internal _tokenApproval;
    mapping(address => mapping(address => bool)) internal _operatorApproval;
    modifier limited {
        require(address(this) == self);
        require(owners[msg.sender]);
        _;
    }
    event Transfer(address indexed, address indexed, uint256 indexed);
    event Approval(address indexed, address indexed, uint256 indexed);
    event ApprovalForAll(address indexed, address indexed, bool);
    constructor() {
        self = address(this);
        owners[msg.sender] = true;
    }
    function addOwner(address[] calldata addresses) public limited {
        uint256 i;
        for(i = 0; i < addresses.length; i++) {
            owners[addresses[i]] = true;
        }
    }
    function removeOwner(address[] calldata addresses) public limited {
        uint256 i;
        for(i = 0; i < addresses.length; i++) {
            owners[addresses[i]] = false;
        }
    }
    function call(address payable target, bytes calldata arguments) public limited returns(bytes memory) {
        bytes memory a;
        (, a) = target.call(arguments);
        return a;
    }
    function supportsInterface(bytes4 interfaceId) public pure returns(bool) {
        return (interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f);
    }
    function balanceOf(address owner) public view returns(uint256) {
        require(owner != address(0));
        return _balance[owner];
    }
    function ownerOf(uint256 tokenId) public view returns(address) {
        require(_owner[tokenId] != address(0));
        return _owner[tokenId];
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public {
        require(_owner[tokenId] != address(0));
        require(msg.sender == _owner[tokenId] || _operatorApproval[_owner[tokenId]][msg.sender] || msg.sender == _tokenApproval[tokenId]);
        _transfer(from, to, tokenId);
        require(_onERC721Received(from, to, tokenId, data));
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        bool a;
        (a, ) = address(this).delegatecall(abi.encode(0xb88d4fde, from, to, tokenId, ""));
        require(a);
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_owner[tokenId] != address(0));
        require(msg.sender == _owner[tokenId] || _operatorApproval[_owner[tokenId]][msg.sender] || msg.sender == _tokenApproval[tokenId]);
        _transfer(from, to, tokenId);
    }
    function approve(address to, uint256 tokenId) public {
        require(to != _owner[tokenId]);
        require(msg.sender == _owner[tokenId]);
        _approve(to, tokenId);
    }
    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator);
        _operatorApproval[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function getApproved(uint256 tokenId) public view returns(address) {
        require(_owner[tokenId] != address(0));
        return _tokenApproval[tokenId];
    }
    function isApprovedForAll(address owner, address operator) public view returns(bool) {
        return _operatorApproval[owner][operator];
    }
    function name() public view returns(string memory) {
        return "Suguru Kawamoto";
    }
    function symbol() public view returns(string memory) {
        return "";
    }
    function tokenURI(uint256 tokenId) public view returns(string memory) {
        require(_owner[tokenId] != address(0));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(abi.encodePacked("{\"name\":\"Suguru Kawamoto\",\"description\":\"Suguru Kawamoto\",\"image\":\"data:image/png;base64,", Base64.encode(png), "\"}"))));
    }
    function mint(address to, uint256 tokenId) public limited {
        require(to != address(0));
        require(_owner[tokenId] == address(0));
        _balance[to]++;
        _owner[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    function burn(uint256 tokenId) public limited {
        require(_owner[tokenId] != address(0));
        _approve(address(0), tokenId);
        _balance[_owner[tokenId]]--;
        emit Transfer(_owner[tokenId], address(0), tokenId);
        _owner[tokenId] = address(0);
    }
    function _approve(address to, uint256 tokenId) internal {
        _tokenApproval[tokenId] = to;
        emit Approval(_owner[tokenId], to, tokenId);
    }
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(from == _owner[tokenId]);
        require(to != address(0));
        _approve(address(0), tokenId);
         _balance[from]--;
         _balance[to]++;
         _owner[tokenId] = to;
         emit Transfer(from, to, tokenId);
    }
    function _onERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal returns(bool) {
        if(to.code.length > 0) {
            require(IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) == IERC721Receiver.onERC721Received.selector);
        }
        return true;
    }
}