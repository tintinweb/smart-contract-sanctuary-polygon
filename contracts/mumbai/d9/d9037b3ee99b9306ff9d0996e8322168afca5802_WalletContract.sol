/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract WalletContract {
    string private TOKEN_TRANSFER = "TOKEN is Transferd Successfully !";
    string private COIN_TRANSFER = "COIN is Transferd Successfully !";

    event TOKEN_Transfered(uint256 amount, address to, string _msg);
    event COIN_Transfered(uint256 amount, address to, string _msg);

    /*
->_AMOUNT = Number of tokens to transfer to other user
- > _touser = User you want transfer the token 
- > Tokenaddress  = Contract address of token 
*/
    function SendToken(
        uint256 _amount,
        address _toUser,
        IERC20 TokenAddress
    ) public {
        require(
            TokenAddress.balanceOf(msg.sender) >= _amount,
            "You Dont Have Enough Balance !"
        );
        require(_amount > 0, "Amount cant be Zero !");

        TokenAddress.transferFrom(msg.sender, _toUser, _amount);
        emit TOKEN_Transfered(_amount, _toUser, TOKEN_TRANSFER);
    }

    /*
->_AMOUNT =  transfer (ETH,BNB,MATIC) to other users
- > _touser = User you want transfer the token 
*/

    function SendCoin(uint256 _amount, address payable _toUser) public payable {
        require(_amount > 0, "You Cannot Enter the Amount to Zero !");
        _toUser.transfer(_amount);
        emit COIN_Transfered(_amount, _toUser, COIN_TRANSFER);
    }
}