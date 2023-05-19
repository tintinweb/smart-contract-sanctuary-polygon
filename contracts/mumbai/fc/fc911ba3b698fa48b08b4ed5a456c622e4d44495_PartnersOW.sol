/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract InvestmentNFT is IERC721 {
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _tokenBalances;
    uint256[] private _allTokens;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function mint(address to, uint256 tokenId) external {
        require(_tokenOwners[tokenId] == address(0), "Token already exists");
        _tokenOwners[tokenId] = to;
        _tokenBalances[to]++;
        _allTokens.push(tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) external {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "Token does not exist");
        _tokenBalances[owner]--;
        delete _tokenOwners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "Zero address is not a valid owner");
        return _tokenBalances[owner];
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        require(
            _tokenOwners[tokenId] == from,
            "Only the token owner can transfer the token"
        );
        require(to != address(0), "Zero address is not a valid recipient");

        _tokenOwners[tokenId] = to;
        _tokenBalances[from]--;
        _tokenBalances[to]++;
        emit Transfer(from, to, tokenId);
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < _allTokens.length, "Index out of bounds");
        return _allTokens[index];
    }
}

contract PartnersOW {
    uint256 public constant MINIMUM_INVESTMENT = 0.00000000000001 ether;

    address private _owner;
    uint256 private _totalInvestment;
    InvestmentNFT private _nftContract;

    mapping(address => uint256) private _investments;
    mapping(address => uint256) private _nftTokens;

    constructor() {
        _owner = msg.sender;
        _nftContract = new InvestmentNFT();
    }

    function invest() external payable {
        require(msg.value >= MINIMUM_INVESTMENT, "Investment amount is less than the minimum investment");

        // Check investment limit
        require(msg.value <= address(this).balance, "Investment limit reached");

        // Add investment to total and record investor's investment
        _totalInvestment += msg.value;
        _investments[msg.sender] += msg.value;

        // Mint investment NFT to investor with investment data
        uint256 tokenId = _getNextTokenId();
        _nftContract.mint(msg.sender, tokenId);
        _nftTokens[msg.sender] = tokenId;
    }

    function withdraw() external {
        require(msg.sender == _owner, "Only the contract owner can withdraw");

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available to withdraw");

        payable(msg.sender).transfer(balance);
    }

    function distributeProfit(uint256 profitPercentage) external {
        require(msg.sender == _owner, "Only the contract owner can distribute profit");

        // Calculate payout for each investor and send payout
        for (uint256 i = 0; i < _totalSupply(); i++) {
            uint256 tokenId = _nftContract.tokenByIndex(i);
            address investor = _nftContract.ownerOf(tokenId);

            uint256 investment = _investments[investor];
            if (investment > 0) {
                uint256 payout = investment + ((investment * profitPercentage) / 100);

                payable(investor).transfer(payout);
                _investments[investor] = 0;
            }
        }

        _totalInvestment = 0;
    }

    function _totalSupply() private view returns (uint256) {
        return _nftContract.balanceOf(address(this));
    }

    function _ownerOf(uint256 tokenId) private view returns (address) {
        return _nftContract.ownerOf(tokenId);
    }

    function _getNextTokenId() private view returns (uint256) {
    return _totalSupply() + 1;
}


    // Implement other internal functions and view functions as needed
}