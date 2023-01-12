/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

contract SBT {

    string public name;

    string public symbol;

    uint256 public totalSupply;

    //状态变量 - 记录owner拥有多少个token
    mapping(address => uint256) public ownerTokensCount;

    //状态变量 - 记录tokenId的所有者
    mapping(uint256 => address) public ownerOf;

    mapping(address => bool) public adminAddress;

    string public baseUri;

    mapping(uint256 => string) private uri;

    bool private locked = false;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    using SafeMath for uint256;

    modifier noLock() {
        require(!locked, "The lock is locked.");
        locked = true;
        _;
        locked = false;
    }

    modifier checkAdmin() {
        require(adminAddress[msg.sender], "invalid admin");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _baseUri){
        name = _name;
        symbol = _symbol;
        baseUri = _baseUri;
        adminAddress[msg.sender] = true;
    }

    function balanceOf(address _owner) external view returns (uint256){
        return ownerTokensCount[_owner];
    }

    function setAdmin(address _address, bool admin) external checkAdmin{
        require(msg.sender != _address, "invalid address");
        adminAddress[_address] = admin;
    }

    function setBaseURI(string memory _baseUri) external checkAdmin{
        baseUri = _baseUri;
    }

    function setTokenURI(uint256 _tokenId, string memory _uri) external checkAdmin{
        uri[_tokenId] = _uri;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return uri[_tokenId];
    }

    function mintTo(address _to, string memory _uri) external noLock checkAdmin{
        uint256 nextTokenId = totalSupply + 1; //token id从1开始
        _mint(_to, nextTokenId);
        uri[nextTokenId] = _uri;
        totalSupply = nextTokenId;
    }

    function _mint(address _to, uint256 _tokenId)  internal virtual {
        require(!_isExistTokenId(_tokenId), "token existed");

        //设置token的所有者
        ownerOf[_tokenId] = _to;

        //所有者拥有的token数量累加
        ownerTokensCount[_to] = ownerTokensCount[_to].add(1);

        //事件
        emit Transfer(address(0), _to, _tokenId);
    }

    function _isExistTokenId(uint256 _tokenId) internal view returns (bool) {
        //查询出tokenId的所有者
        address owner = ownerOf[_tokenId];
        if (address(0) != owner) {
            return true;
        }
        return false;
    }

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}