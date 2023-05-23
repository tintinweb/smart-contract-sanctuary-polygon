/**
 *Submitted for verification at polygonscan.com on 2023-05-22
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
    InvestmentNFT private _nftContract;

    mapping(address => uint256) private _investments;
    mapping(address => uint256) private _nftTokens;

    uint256 private _totalWithdrawn;
    uint256 private _totalDeposited;

    constructor() {
        _owner = msg.sender;
        _nftContract = new InvestmentNFT();
    }

    function invest() external payable {
        require(msg.value >= MINIMUM_INVESTMENT, "Investment amount is less than the minimum investment");

        // Mint investment NFT to investor with investment data
        uint256 tokenId = _getNextTokenId();
        _nftContract.mint(msg.sender, tokenId);
        _nftTokens[msg.sender] = tokenId;

        // Record investor's investment
        _investments[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == _owner, "Only the contract owner can withdraw");

        uint256 balance = address(this).balance;
        require(balance >= amount, "Insufficient funds in the contract");

        // Update total withdrawn amount
        _totalWithdrawn += amount;

        // Transfer funds to the contract owner
        payable(msg.sender).transfer(amount);
    }

    function distributeProfit() external {
        require(msg.sender == _owner, "Only the contract owner can distribute profit");

        // Calculate the difference between total withdrawn and total deposited amount
        int256 difference = int256(_totalDeposited) - int256(_totalWithdrawn);

        // Calculate profit percentage based on the difference
        int256 profitPercentage = (difference * 100) / int256(_totalWithdrawn);

        // Iterate over each investor and distribute their share of profit and initial investment
        for (uint256 i = 0; i < _totalSupply(); i++) {
            uint256 tokenId = _nftContract.tokenByIndex(i);
            address investor = _nftContract.ownerOf(tokenId);

            uint256 investment = _investments[investor];
            if (investment > 0) {
                int256 investorProfit = (int256(investment) * profitPercentage) / 100;
                uint256 totalPayout;

                if (investorProfit >= 0) {
                    // Calculate total payout including profit
                    totalPayout = investment + uint256(investorProfit);
                } else {
                    // Calculate total payout considering loss (negative profit)
                    totalPayout = investment - uint256(-investorProfit);
                }

                // Transfer funds from contract's balance to investor
                payable(investor).transfer(totalPayout);

                // Deduct the profit (or loss) from the investor's investment
                _investments[investor] -= uint256(investorProfit);
            }
        }
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

    function depositFunds() external payable {
        require(msg.sender == _owner, "Only the contract owner can deposit funds");
    }

    // Implement other internal functions and view functions as needed
}