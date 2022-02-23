// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

import "./ERC721A.sol";

contract GDO is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;

    uint256 public PRICE = 0.016 ether;

    string private _uri;
    mapping(address => uint256) private _publicNumberMinted;

    uint256 public immutable maxTotalSupply;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory initURI) ERC721A("G DO", "GDO", 20) {
        _uri = initURI;
        maxTotalSupply = 10000;
    }

    function _baseURI() internal view  override(ERC721A) returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) public virtual onlyOwner{
        _uri = newuri;
    }

    function mint(uint256 num) external payable {
        require(status == Status.PublicSale, "GM006");
        verified(num);
        _safeMint(msg.sender,num);
        _publicNumberMinted[msg.sender] = _publicNumberMinted[msg.sender] + 1;
    }

    function verified(uint256 num) private {
        require(num > 0, 'GM011');
        require(msg.value >= PRICE * num, "GM002");
        if (msg.value > PRICE * num) {
            payable(msg.sender).transfer(msg.value - PRICE * num);
        }
        require(totalSupply() + num <= maxTotalSupply, "GM003");
        require(tx.origin == msg.sender, "GM007");
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function publicNumberMinted(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: number minted query for the zero address"
        );
        return _publicNumberMinted[owner];
    }

    function release(address to) public virtual nonReentrant onlyOwner{
        require(address(this).balance > 0, "GM005");
        Address.sendValue(payable(to), address(this).balance);
        emit PaymentReleased(owner(), address(this).balance);
    }
}