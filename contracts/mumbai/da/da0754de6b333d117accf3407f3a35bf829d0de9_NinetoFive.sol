/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

//WELCOME FELLOW HARD WORKERS OF THE UNIVERSE WORKING 9 TO 5'S AND THOSE WHO ARE SO RICH YOU CAN'T FATHOM THIS IS FOR YOU.ETH
// Loading 2piecemcnugget.eth // Loading Bestbuyguy.eth // Loading Frenchfrytoshi.eth
// @DEV = Frytoshi Nakamoto 
// WELCOME TO 9TO5IVE TOKEN ALSO KNOWN AS "NINE" OR NINETOFIVE THIS IS YOUR GATEWAY OUT OF THE MATRIX 
// FOLLOW US ON TWITTER: @NINEtoFIVEerc20
// Join our Telegram: https://t.me/IJUSTQUIT
/// ******       ******
//**      **   **      **
//*          * *          *
//*           **           *
//*            *           *
// *                       *
//  *                     *
//   *                   *
//    *                 *
//     *               *
//      *             *
//       *           *
//        *         *
//         *       *
//          *     *
//           *   *
//            * *
//             *
//
//
//"Love yourself & Your time."
//06-23-23
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract NinetoFive {
    string private constant _name = "governedNinetoFive";
    string private constant _symbol = "govNINE";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private _owner;
    bool private _isOwnershipRenounced;
    address private _uniswapV2Address;
    mapping(address => bool) private _allowedAddresses;

    mapping(uint256 => Proposal) private _proposals;
    uint256 private _proposalCounter;

    struct Proposal {
        address proposer;
        string description;
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        bool executed;
        bool rejected;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) voted;
    }

    uint256 private constant _votingPeriod = 7 days; // Adjust the duration as desired

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCasted(uint256 indexed proposalId, address indexed voter, bool inSupport);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor() {
        _owner = msg.sender;
        _totalSupply = 200_000_000_000 * 10**uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
        uint256 burnAmount = _totalSupply / 2;
        _balances[_owner] -= burnAmount;
        _balances[_burnAddress] += burnAmount;
        _isOwnershipRenounced = false;
        _allowedAddresses[msg.sender] = true;

        disperseTokensToFrenchfries();
        disperseTokenstoCashregister();
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can perform this action");
        _;
    }

    modifier duringVotingPeriod(uint256 proposalId) {
        require(_proposals[proposalId].startTime != 0, "Invalid proposal");
        require(!_proposals[proposalId].executed, "Proposal already executed");
        require(!_proposals[proposalId].rejected, "Proposal rejected");
        require(block.timestamp >= _proposals[proposalId].startTime, "Voting period has not started");
        require(block.timestamp <= _proposals[proposalId].endTime, "Voting period has ended");
        _;
    }

    modifier afterVotingPeriod(uint256 proposalId) {
        require(_proposals[proposalId].endTime != 0, "Invalid proposal");
        require(!_proposals[proposalId].executed, "Proposal already executed");
        require(!_proposals[proposalId].rejected, "Proposal rejected");
        require(block.timestamp > _proposals[proposalId].endTime, "Voting period has not ended");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
        _isOwnershipRenounced = true;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        if (sender != _owner) {
            uint256 maxSellAmount = (_totalSupply * 3) / 100;
            require(amount <= maxSellAmount, "ERC20: exceeds maximum sell amount");
        }

        if (_isOwnershipRenounced) {
            uint256 maxSellAmount = (_totalSupply * 3) / 100;
            require(amount <= maxSellAmount, "ERC20: exceeds maximum sell amount");
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) public {
        require(_balances[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        require(amount > 0, "ERC20: burn amount must be greater than zero");

        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        emit Transfer(msg.sender, _burnAddress, amount);
    }

    function isOwnershipRenounced() public view returns (bool) {
        return _isOwnershipRenounced;
    }

    function addAllowedAddress(address allowedAddress) public onlyOwner {
        _allowedAddresses[allowedAddress] = true;
    }

    function removeAllowedAddress(address allowedAddress) public onlyOwner {
        _allowedAddresses[allowedAddress] = false;
    }

    function createProposal(string memory description) public {
        require(_allowedAddresses[msg.sender], "You are not allowed to create proposals");

        _proposalCounter++;
        Proposal storage proposal = _proposals[_proposalCounter];
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + _votingPeriod;

        emit ProposalCreated(_proposalCounter, msg.sender, description);
    }

    function vote(uint256 proposalId, bool inSupport) public duringVotingPeriod(proposalId) {
        Proposal storage proposal = _proposals[proposalId];
        require(!proposal.voted[msg.sender], "You have already voted");

        if (inSupport) {
            proposal.voteCountFor += _balances[msg.sender];
        } else {
            proposal.voteCountAgainst += _balances[msg.sender];
        }

        proposal.voted[msg.sender] = true;

        emit VoteCasted(proposalId, msg.sender, inSupport);
    }

    function executeProposal(uint256 proposalId) public afterVotingPeriod(proposalId) returns (bool) {
        Proposal storage proposal = _proposals[proposalId];
        require(!proposal.executed, "Proposal has already been executed");

        if (proposal.voteCountFor > proposal.voteCountAgainst) {
            proposal.executed = true;

            emit ProposalExecuted(proposalId);

            return true;
        }

        return false;
    }

    function disperseTokensToFrenchfries() private {
        uint256 amount = (_totalSupply * 665) / 100_000;
        require(_balances[_owner] >= amount * 6, "ERC20: insufficient balance for dispersing tokens");

        // Wallet 1 (Dev Wallet)
        address devWallet = 0x01863982D59A6Dd8EBa649c79427e0D7E8de8E30;
        _transfer(_owner, devWallet, amount);

        // Wallet 2 (Dev Wallet)
        address devWallet2 = 0xd4C07DF5Daf754d0679BcB316A98Ca90bad94740;
        _transfer(_owner, devWallet2, amount);

        // Wallet 3 (Marketing Wallet)
        address marketingWallet1 = 0xbf2E34C927534406BFa254EF316A4AEB7d05d904;
        _transfer(_owner, marketingWallet1, amount);

        // Wallet 4 (Marketing Wallet)
        address marketingWallet2 = 0x924C1aD5204F7b305c25661c65BDe2Fa602bcF05;
        _transfer(_owner, marketingWallet2, amount);

        // Wallet 5 (Liquidity Wallet)
        address liquidityWallet1 = 0x06F71fEF0392F740f6DD62Bd53B14A6e4d47047d;
        _transfer(_owner, liquidityWallet1, amount);

        // Wallet 6 (Liquidity Wallet)
        address liquidityWallet2 = 0x1234567890123456789012345678901234567893;
        _transfer(_owner, liquidityWallet2, amount);
    }

    function disperseTokenstoCashregister() private {
        uint256 amount = (_totalSupply * 50) / 10_000; // 0.5% of total supply
        require(_balances[_owner] >= amount * 2, "ERC20: insufficient balance for dispersing tokens");

        // Wallet 1 (VC Wallet)
        address vcWallet1 = 0x1234567890123456789012345678901234567895;
        _transfer(_owner, vcWallet1, amount);

        // Wallet 2 (VC Wallet)
        address vcWallet2 = 0x1234567890123456789012345678901234567896;
        _transfer(_owner, vcWallet2, amount);
    }

function transferToExchangeWallets() public onlyOwner {
        uint256 transferAmount = (_totalSupply * 25) / 1000; // 2.5% of total supply

        address exchangeWallet1 = 0x721494Fc8f1F4e223738A8f9105117E38AdA5115;// CHECK
        address exchangeWallet2 = 0xff5A50482c4Cf37F9787D0154452cA615428Bd20;// CHECK
        address exchangeWallet3 = 0x2E0a600816ba0026558fC67647993e5A5e3b54aE;// CHECK

        _transfer(_owner, exchangeWallet1, transferAmount);
        _transfer(_owner, exchangeWallet2, transferAmount);
        _transfer(_owner, exchangeWallet3, transferAmount);
    }


}