/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract TokenTransferContract {
    address private constant MATIC_TOKEN_ADDRESS = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0; // Endereço do token MATIC

    function transferMaticTokens(address recipient, uint256 amount) external {
        IERC20 maticToken = IERC20(MATIC_TOKEN_ADDRESS);
        require(maticToken.transfer(recipient, amount), "Falha ao transferir tokens MATIC");
    }
}