/**
 *Submitted for verification at polygonscan.com on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IMultiHonor {
    function POC(uint256 tokenId) view external returns(uint64);
    function VEPower(uint256 tokenId) view external returns(uint256);
    function VEPoint(uint256 tokenId) view external returns(uint64);
    function EventPoint(uint256 tokenId) view external returns(uint64);
    function TotalPoint(uint256 tokenId) view external returns(uint64); 
    function Level(uint256 tokenId) view external returns(uint8);
    function addPOC(uint256[] calldata ids, uint64[] calldata poc) external;
}

interface IERC721Enumerable {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract POC_SemiToken is IERC20 {
    address public honor;
    address public idcard;
    uint256 _totalSupply;
    address public owner;
    address public pendingOwner;

    string public name = "POC_SemiToken";
    string public symbol = "POCST";
    uint8 public decimals = 0;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwner(address newOwner) external onlyOwner {
        pendingOwner = newOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    event SetIssuer(address indexed issuer, uint256 cap);

    mapping(address => uint256) public cap;
    mapping(address => mapping(address => uint256)) public _allowance;

    constructor (address idcard_, address honor_) {
        owner = msg.sender;
        idcard = idcard_;
        honor = honor_;
    }

    function setIssuer(address issuer, uint256 cap_) external onlyOwner {
        cap[issuer] = cap_;
        emit SetIssuer(issuer, cap_);
    }

    function balanceOf(address account) external view returns (uint256) {
        if (cap[account] > 0) {
            return cap[account];
        }
        uint256 tokenId = IERC721Enumerable(idcard).tokenOfOwnerByIndex(account, 0);
        return IMultiHonor(honor).POC(tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // issue poc by issuer
    function transfer(address to, uint256 amount) external returns (bool) {
        require(cap[msg.sender] >= amount, "transfer not allowed");
        cap[msg.sender] -= amount;
        uint256 tokenId = IERC721Enumerable(idcard).tokenOfOwnerByIndex(to, 0);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        uint64[] memory pocs = new uint64[](1);
        pocs[0] = uint64(amount);
        IMultiHonor(honor).addPOC(ids, pocs);
        _totalSupply += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // issue poc from issuer
    function transferFrom(
        address issuer,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(cap[issuer] >= amount, "transfer not allowed");
        _allowance[msg.sender][issuer] -= amount;
        cap[issuer] -= amount;
        uint256 tokenId = IERC721Enumerable(idcard).tokenOfOwnerByIndex(to, 0);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        uint64[] memory pocs = new uint64[](1);
        pocs[0] = uint64(amount);
        IMultiHonor(honor).addPOC(ids, pocs);
        _totalSupply += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // issuer's allowance to spender
    function allowance(address issuer, address spender) external view returns (uint256) {
        return _allowance[issuer][spender];
    }

    // issuer approve to spender
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}