// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IBEP20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract HUNDonation {
    address public owner;
    uint256 public minDonation = 5 * 10 ** 18; // 5 BNB or BUSD or 100 HUN
    uint256 private constant TOKEN_DECIMALS = 18;

    mapping(address => bool) public acceptedTokens;

    event Donation(
        address indexed donor,
        address indexed token,
        uint256 amount
    );

    constructor(address _busdAddress, address _hunAddress) {
        owner = msg.sender;
        acceptedTokens[address(0)] = true; // BNB
        acceptedTokens[_busdAddress] = true; // BUSD
        acceptedTokens[_hunAddress] = true; // HUN
    }

    function donate(address token, uint256 amount) public payable {
        require(acceptedTokens[token], "Token not accepted");
        require(amount >= minDonation, "Minimum donation not met");

        uint256 tokenAmount = amount * 10 ** TOKEN_DECIMALS;

        if (token == address(0)) {
            require(msg.value == tokenAmount, "Incorrect BNB value");
        } else {
            require(
                IBEP20(token).transferFrom(
                    msg.sender,
                    address(this),
                    tokenAmount
                ),
                "Transfer failed"
            );
        }

        emit Donation(msg.sender, token, tokenAmount);
    }

    function withdraw(address token, uint256 amount) public {
        require(msg.sender == owner, "Only owner can withdraw");

        uint256 tokenAmount = amount * 10 ** TOKEN_DECIMALS;

        if (token == address(0)) {
            payable(owner).transfer(amount);
        } else {
            require(
                IBEP20(token).transfer(owner, tokenAmount),
                "Transfer failed"
            );
        }
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "Only owner can transfer ownership");
        owner = newOwner;
    }

    function addAcceptedToken(address token) public {
        require(msg.sender == owner, "Only owner can add accepted tokens");
        acceptedTokens[token] = true;
    }

    function removeAcceptedToken(address token) public {
        require(msg.sender == owner, "Only owner can remove accepted tokens");
        acceptedTokens[token] = false;
    }
}