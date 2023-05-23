/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_tokenOwners[tokenId] == address(0), "ERC721: token already minted");

        _balances[to] += 1;
        _tokenOwners[tokenId] = to;
        _totalSupply += 1;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "ERC721: burn of nonexistent token");

        _balances[owner] -= 1;
        delete _tokenOwners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract InvestmentFund is ERC721, Ownable {
    mapping(address => uint256) public investments;
    uint256 public totalInvestedAmount;

    constructor() {
        _mint(msg.sender, 1); // Mint NFT for contract owner
    }

    function invest() external payable {
        require(msg.value > 0, "Amount must be greater than zero");

        if (investments[msg.sender] == 0) {
            _mint(msg.sender, totalSupply() + 1);
        }

        investments[msg.sender] += msg.value;
        totalInvestedAmount += msg.value;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");

        address investor = ownerOf(1); // Use token ID 1 for contract owner
        (bool success, ) = payable(investor).call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function keepFunds(uint256 amount) external view onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
    }

    function distributeProfits() external onlyOwner {
        require(totalInvestedAmount > 0, "No investments made");

        uint256 currentContractBalance = address(this).balance;
        uint256 profitPercentage = ((currentContractBalance - totalInvestedAmount) * 10000) / totalInvestedAmount;
        totalInvestedAmount = currentContractBalance;

        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (exists(i)) {
                address investor = ownerOf(i);
                uint256 investment = investments[investor];
                uint256 profit = (investment * profitPercentage) / 10000;
                investments[investor] += profit;

                // Transfer funds to the wallet where the NFT is currently stored
                (bool success, ) = payable(investor).call{value: profit}("");
                require(success, "Profit transfer failed");

                _burn(i);
            }
        }
    }
}