//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

import "./ERC721.sol";

contract HauDev is ERC721 {
    string public name; // ERC721 metadata
    string public symbol; // ERC721 metadata

    uint256 public tokenCount;

    mapping(uint256 => string) private _tokenURIs; //lưu trữ URI của mỗi token

    constructor (string memory _name, string memory _symbol){
        name = _name; // tên của token
        symbol = _symbol; // symbol của token
    }

    function tokenURI(uint256 tokenId) public view returns(string memory){  // trả về URI của tokenId
        require(_owners[tokenId] != address(0), "Token ID does not exist");
        return _tokenURIs[tokenId];
    }

    //tạo ra một token mới trong contract
    //Hàm này sẽ tăng giá trị của biến tokenCount lên 1, 
    //thiết lập thông tin chủ sở hữu của token và URI của token tương ứng với tokenCount trong mapping _tokenURIs
    function mint() public {
        tokenCount += 1; //
        string memory mockTokenURI = "https://madlads.s3.us-west-2.amazonaws.com/json/9966.json";

        _balances[msg.sender] += 1;
        _owners[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = mockTokenURI;

        //phát ra sự kiện Transfer để thông báo rằng một token mới đã được tạo ra và được chuyển
        // đến địa chỉ msg.sender. Trong trường hợp này, address(0) được sử dụng để thể hiện rằng token
        // mới được tạo ra từ một địa chỉ không hợp lệ
        emit Transfer(address(0), msg.sender, tokenCount);

    }

    //kiểm tra xem contract HauDev có hỗ trợ các interface nào trong chuẩn ERC721
    function supportInterface(bytes4 interfaceId) public pure override returns(bool){
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
}