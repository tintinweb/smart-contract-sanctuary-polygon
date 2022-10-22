// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";

error FundMe_NotOwner();
error FundMe_WithdrawalFailed();

contract FundMeWithNoneNativeToken {
    IERC20 public immutable token;

    address private immutable i_owner;
    mapping (address => uint256) private s_not_withdrawn_addressToAmountFunded;
    mapping (address => uint256) private s_addressToAmountFunded;
    address[] private s_all_funders;
    address[] private s_current_funders;
    uint256 private s_all_deposited_amount;
    uint256 private s_stored_amount;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe_NotOwner();
        _;
    }

    constructor(address _token) {
        i_owner = msg.sender;
        token = IERC20(_token);
    }

    function fund(uint256 _amount) external {
        s_all_deposited_amount += _amount;
        s_stored_amount += _amount;
        s_not_withdrawn_addressToAmountFunded[msg.sender] += _amount;
        if (s_not_withdrawn_addressToAmountFunded[msg.sender] == 0) {
            s_current_funders.push(msg.sender);
        }
        s_addressToAmountFunded[msg.sender] += _amount;
        if (s_addressToAmountFunded[msg.sender] == 0) {
            s_all_funders.push(msg.sender);
        }
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw() public payable onlyOwner {
        address[] memory funders = s_current_funders;

        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_not_withdrawn_addressToAmountFunded[funder] = 0;
        }
        s_current_funders = new address[](0);

        bool transferSuccess = token.transfer(msg.sender, s_stored_amount);
        if (!transferSuccess) revert FundMe_WithdrawalFailed();

        s_stored_amount = 0;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getAllFunders() public view returns (address[] memory) {
        return s_all_funders;
    }

    function getAddressToAmountFunded(address funder) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getStoredBalance() public view returns (uint256) {
        return s_stored_amount;
    }

    function getAllStoredAmount() public view returns (uint256) {
        return s_all_deposited_amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

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