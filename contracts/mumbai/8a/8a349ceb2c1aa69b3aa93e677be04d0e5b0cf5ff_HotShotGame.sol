/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

// @title HotShotGame
// @title Website https://hotshotsmartgame.com/
// @title Interface : Token Standard #20. https://github.com/ethereum/EIPs/issue

interface BEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract HotShotGame {
    using SafeMath for uint256;

    address public signer;
    address payable feeReceiver1 = 0x1C62daf74Fd19Ac7eD8b013bD95c02933dA0B7C8;
    address payable feeReceiver2 = 0x19826Ea42a927541a9c21682A109b073EeDa6F81;
    address payable feeReceiver3 = 0xD2a821D113523BA400848D6062ED03a2134366EA;
    address payable feeReceiver4 = 0xD4c1Fca98b551C65F50a3331F2581D75b840A57F;
    address payable feeReceiver5 = 0x5fAC2FBC3eD6bb68AeF80310E83C3f26552dD5c4;
    uint8 public fees = 20;

    event Deposit(address buyer, address coin, uint256 amount);
    event Sell(address buyer, address coin, uint256 amount);
    
    // @dev Detects Authorized Signer.
    modifier onlySigner(){
        require(msg.sender == signer,"You are not authorized signer.");
        _;
    }

    // @dev Returns coin balance on this contract.
    function getBalanceSheet(address _coin) public view returns(uint256 bal){
        bal =  BEP20(_coin).balanceOf(address(this));
        return bal;
    }

    // @dev Restricts unauthorized access by another contract.
    modifier security{
        uint size;
        address sandbox = msg.sender;
        assembly  { size := extcodesize(sandbox) }
        require(size == 0,"Smart Contract detected.");
        _;
    }

    constructor() public {
        signer = msg.sender;
    }
    
    // @dev Deposit coins which are available in this contract.
    function deposit(address _coin, uint256 _amount) public security{
        require(BEP20(_coin).transferFrom(msg.sender,address(this),_amount));
        feesDistribution(_coin,_amount.mul(fees).div(100));
        emit Deposit(msg.sender, _coin, _amount.div(1e18));
    }

    // @dev Fee Distribution charge to Fee Receivers.
    function feesDistribution(address _coin, uint256 _amount) internal{
        uint256 _fees = _amount.div(5);
        BEP20(_coin).transfer(feeReceiver1,_fees);
        BEP20(_coin).transfer(feeReceiver2,_fees);
        BEP20(_coin).transfer(feeReceiver3,_fees);
        BEP20(_coin).transfer(feeReceiver4,_fees);
        BEP20(_coin).transfer(feeReceiver5,_fees);
    }

    // @dev Overrides Fees on this contract
    function feesSettlement(uint8 _fees) external onlySigner security{
        fees = _fees;
    }

    // @dev Sell coins to buyer
    function sell(address buyer, address _coin, uint _amount) external onlySigner security{
        require(BEP20(_coin).balanceOf(address(this))>=_amount,"Insufficient Fund!");
        BEP20(_coin).transfer(buyer, _amount);
        emit Sell(buyer, _coin, _amount);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
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
}