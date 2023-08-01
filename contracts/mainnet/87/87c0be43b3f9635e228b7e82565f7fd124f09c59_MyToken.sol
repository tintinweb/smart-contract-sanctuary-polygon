/**
 *Submitted for verification at polygonscan.com on 2023-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public admin;
    address public tokenOwner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public blacklisted;
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakeTime;
    mapping(address => uint256) public stakeRewardClaimed;

    uint256 public taxFeePercentage;
    address public taxFeeAdminAddress;

    bool public paused;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Blacklist(address indexed account);
    event Unblacklist(address indexed account);
    event Paused();
    event Unpaused();
    event Mint(address indexed to, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        address _admin,
        address _taxFeeAdminAddress,
        uint256 _taxFeePercentage
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10**uint256(_decimals);
        admin = _admin;
        tokenOwner = msg.sender;
        balanceOf[tokenOwner] = totalSupply;
        taxFeeAdminAddress = _taxFeeAdminAddress;
        taxFeePercentage = _taxFeePercentage;
    }

    function burn(uint256 amount) public whenNotPaused {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function mint(address to, uint256 amount) public onlyAdmin whenNotPaused {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
        emit Mint(to, amount);
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
        require(to != address(0), "Invalid recipient address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        if (taxFeePercentage > 0) {
            uint256 taxFee = (amount * taxFeePercentage) / 100;
            balanceOf[taxFeeAdminAddress] += taxFee;
            emit Transfer(msg.sender, taxFeeAdminAddress, taxFee);
            amount -= taxFee;
        }

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferOwnership(address newOwner) public onlyAdmin {
        require(newOwner != address(0), "Invalid new owner address");
        tokenOwner = newOwner;
    }

    function recoverTokens(address tokenAddress, uint256 amount) public onlyAdmin {
        require(tokenAddress != address(this), "Cannot recover native token");
        require(tokenAddress != address(0), "Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Insufficient contract balance");
        token.transfer(msg.sender, amount);
    }

    function recoverEth(uint256 amount) public onlyAdmin {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(msg.sender).transfer(amount);
    }

    function recoverNFT(address nftAddress, uint256 tokenId) public onlyAdmin {
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == address(this), "NFT not owned by contract");
        nft.transferFrom(address(this), msg.sender, tokenId);
    }

    function airdrop(address[] memory recipients, uint256[] memory amounts) public onlyAdmin {
        require(recipients.length == amounts.length, "Invalid input length");

        for (uint256 i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
    }

    function pause() public onlyAdmin {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyAdmin {
        paused = false;
        emit Unpaused();
    }

    function stake(uint256 amount) public whenNotPaused {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        stakedBalance[msg.sender] += amount;
        stakeTime[msg.sender] = block.timestamp;
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) public whenNotPaused {
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");
        stakedBalance[msg.sender] -= amount;
        balanceOf[msg.sender] += amount;
        emit Unstake(msg.sender, amount);
    }

    function claimStakeReward() public whenNotPaused {
        uint256 reward = calculateStakeReward(msg.sender);
        require(reward > 0, "No rewards to claim");
        stakeRewardClaimed[msg.sender] += reward;
        balanceOf[msg.sender] += reward;
    }

    function calculateStakeReward(address account) internal view returns (uint256) {
        // Calculate the reward based on the staking duration and other factors
        // Implementation depends on your specific staking mechanism.
        // Return 0 if no rewards to claim, or the actual reward amount.
    }

    function withdrawAll() public onlyAdmin {
        uint256 contractBalance = balanceOf[address(this)];
        transfer(msg.sender, contractBalance);
    }

    function blacklistAccount(address account) public onlyAdmin {
        blacklisted[account] = true;
        emit Blacklist(account);
    }

    function unblacklistAccount(address account) public onlyAdmin {
        blacklisted[account] = false;
        emit Unblacklist(account);
    }

    function wrapEth() public payable whenNotPaused {
        require(msg.value > 0, "No ether sent");
        balanceOf[msg.sender] += msg.value;
    }

    function unwrapEth(uint256 amount) public whenNotPaused {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function randomTokenMint(address recipient) public onlyAdmin whenNotPaused {
        uint256 amountToMint = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, recipient))) % 1000;
        mint(recipient, amountToMint);
    }

    function setTaxFeePercentage(uint256 feePercentage) public onlyAdmin {
        require(feePercentage <= 100, "Fee percentage must be <= 100");
        taxFeePercentage = feePercentage;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}