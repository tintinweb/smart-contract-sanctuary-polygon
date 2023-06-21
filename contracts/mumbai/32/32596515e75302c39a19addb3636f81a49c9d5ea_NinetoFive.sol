/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

//WELCOME FELLOW HARD WORKERS OF THE UNIVERSE WORKING 9 TO 5'S AND THOSE WHO ARE SO RICH YOU CAN'T FATHOM THIS IS FOR YOU.ETH
// Loading 2piecemcnugget.eth // Loading Bestbuyguy.eth // Loading Frenchfrytoshi.eth
// @DEV = Frytoshi Nakamoto 
// WELCOME TO 9TO5IVE TOKEN ALSO KNOWN AS "NINE" OR NINETOFIVE THIS IS YOUR GATEWAY OUT OF THE MATRIX 
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract NinetoFive {
    string private constant _name = "testing123";
    string private constant _symbol = "9totest";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private _owner;
    uint256 private _maxWalletSize;
    bool private _isOwnershipRenounced;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);

    constructor() {
        _owner = msg.sender;
        _totalSupply = 200_000_000_000 * 10**uint256(_decimals);
        _maxWalletSize = (_totalSupply * 3) / 100;
        _balances[msg.sender] = _totalSupply;
        uint256 burnAmount = _totalSupply / 2;
        _balances[_owner] -= burnAmount;
        _balances[_burnAddress] += burnAmount;
        _isOwnershipRenounced = false;

    
        disperseTokensToDevTeam();
        disperseTokenstoVC();
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
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

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
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
            require(_balances[recipient] + amount <= _maxWalletSize, "Exceeds maximum wallet size");
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

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        require(maxWalletSize > 0, "Max wallet size must be greater than zero");
        _maxWalletSize = maxWalletSize;
    }

    function getMaxWalletSize() public view returns (uint256) {
        return _maxWalletSize;
    }

    function isOwnershipRenounced() public view returns (bool) {
        return _isOwnershipRenounced;
    }

    function disperseTokensToDevTeam() private {
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

        // Wallet 5 (Liquidity Wallet) // input neomatrix addresses below 
        address liquidityWallet1 = 0x1234567890123456789012345678901234567892;
        _transfer(_owner, liquidityWallet1, amount);

        // Wallet 6 (Liquidity Wallet) // input neomatrix address below
        address liquidityWallet2 = 0x1234567890123456789012345678901234567893;
        _transfer(_owner, liquidityWallet2, amount);
    }


    function disperseTokenstoVC() private {
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

        address exchangeWallet1 = 0x1234567890123456789012345678901234567890;
        address exchangeWallet2 = 0x0987654321098765432109876543210987654321;
        address exchangeWallet3 = 0x9876543210987654321098765432109876543210;

        _transfer(_owner, exchangeWallet1, transferAmount);
        _transfer(_owner, exchangeWallet2, transferAmount);
        _transfer(_owner, exchangeWallet3, transferAmount);
    }
}