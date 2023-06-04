/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT

/**

 /$$$$$$$                      /$$                                                   /$$$$$$$   /$$$$$$   /$$$$$$ 
| $$__  $$                    |__/                                                  | $$__  $$ /$$__  $$ /$$__  $$
| $$  \ $$  /$$$$$$   /$$$$$$$ /$$ /$$    /$$ /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$ | $$  \ $$| $$  \ $$| $$  \ $$
| $$  | $$ /$$__  $$ /$$_____/| $$|  $$  /$$//$$__  $$ /$$__  $$ /$$_____/ /$$__  $$| $$  | $$| $$$$$$$$| $$  | $$
| $$  | $$| $$$$$$$$|  $$$$$$ | $$ \  $$/$$/| $$$$$$$$| $$  \__/|  $$$$$$ | $$$$$$$$| $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$_____/ \____  $$| $$  \  $$$/ | $$_____/| $$       \____  $$| $$_____/| $$  | $$| $$  | $$| $$  | $$
| $$$$$$$/|  $$$$$$$ /$$$$$$$/| $$   \  $/  |  $$$$$$$| $$       /$$$$$$$/|  $$$$$$$| $$$$$$$/| $$  | $$|  $$$$$$/
|_______/  \_______/|_______/ |__/    \_/    \_______/|__/      |_______/  \_______/|_______/ |__/  |__/ \______/ 
                                                                                                                  
 */

pragma solidity ^0.8.19;

contract DesiverseDAO {
    // Total supply of NFTs
    uint256 public constant totalSupply = 1111;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from token ID to token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from account to whether it has an NFT with id
    mapping(address => mapping(uint256 => bool)) private _hasNFT;

    // Owner of the contract
    address public _owner;

    // Name of the contract
    string private _name = "DesiverseDAO Airdrop NFTs";

    // Symbol of the contract
    string private _symbol = "DDANFT";

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    // Constructor
    constructor() {
        _owner = msg.sender;
        _mint(msg.sender, 0, totalSupply);
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    // Balance function
    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return _balances[id][account];
    }

    // Set approval function
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Approval function
    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    // Safe transfer function
    function safeTransferFrom(address from, address to, uint256 id) external onlyOwner {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(!_hasNFT[to][id], "Recipient already has an NFT");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= 1, "Transfer amount exceeds balance");

        _balances[id][from] = fromBalance - 1;
        _balances[id][to] = 1;
        _hasNFT[to][id] = true;
        emit Transfer(from, to, id);
    }

    // Safe batch transfer function
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids) external onlyOwner {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(!_hasNFT[to][id], "Recipient already has an NFT");

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= 1, "Transfer amount exceeds balance");

            _balances[id][from] = fromBalance - 1;
            _balances[id][to] = 1;
            _hasNFT[to][id] = true;
            emit Transfer(from, to, id);
        }
    }

    // Mint function
    function mint(address account, uint256 id, uint256 amount) external onlyOwner {
        require(account != address(0), "Mint to the zero address");

        if (id == 0) {
            require(!_hasNFT[account][id], "Account already has an NFT");
            _hasNFT[account][id] = true;
        }

        _mint(account, id, amount);
    }

    // Update total supply function of NFTs id onlyOwner
    function updateTotalSupply(uint256 id, uint256 newTotalSupply) external onlyOwner {
        require(newTotalSupply > _balances[id][msg.sender], "New total supply must be greater than current balance");

        _mint(msg.sender, id, newTotalSupply - _balances[id][msg.sender]);
    }

    // Burn function
    function burn(address account, uint256 id, uint256 amount) external onlyOwner {
        require(account != address(0), "Burn from the zero address");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;
    }

    // URI functions
    function setURI(uint256 id, string memory newURI) external onlyOwner {
        _tokenURIs[id] = newURI;
    }

    function uri(uint256 id) external view returns (string memory) {
        return _tokenURIs[id];
    }

    // Owner functions
    function owner() external view returns (address) {
        return _owner;
    }

    // Transfer ownership function
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Transfer ownership to the zero address");
        _owner = newOwner;
        
        uint256 fromBalance = _balances[0][msg.sender];
        _balances[0][msg.sender] = 0;
        _balances[0][newOwner] = fromBalance;
    }

    // Renounce ownership function
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }

    // Internal functions
    function _transfer(address from, address to, uint256 id) internal {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(!_hasNFT[to][id], "Recipient already has an NFT");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= 1, "Transfer amount exceeds balance");

        _balances[id][from] = fromBalance - 1;
        _balances[id][to] = 1;
        _hasNFT[to][id] = true;
    }

    function _mint(address account, uint256 id, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _balances[id][account] += amount;
    }

    // Check if account has an NFT
    function hasNFT(address account, uint256 id) external view returns (bool) {
        return _hasNFT[account][id];
    }

    // Function to withdraw token sent to the contract
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Withdraw token to the zero address");
        require(amount > 0, "Withdraw amount must be greater than zero");

        (bool success, ) = token.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount));
        require(success, "Transfer failed");
    }

    // Function to withdraw ether sent to the contract
    function withdrawEther(uint256 amount) external onlyOwner {
        require(amount > 0, "Withdraw amount must be greater than zero");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // Contract name function
    function name() external view returns (string memory) {
        return _name;
    }

    // Contract symbol function
    function symbol() external view returns (string memory) {
        return _symbol;
    }
}