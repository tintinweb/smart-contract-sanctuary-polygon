/**
 *Submitted for verification at polygonscan.com on 2022-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ReturnLimitTest {
    
    mapping(uint256 => mapping(address => uint256)) public _balances;
    uint256[] public token_array;
    mapping (uint256 => uint256) public token_array_index;
    address[] public user_array;
    mapping (address => uint256) public user_array_index;


    // Balance[] public balanceList;
    struct TokenBalance{
        uint256 token_id;
        Balance[] balance;
    }
    struct Balance {
        address user;
        uint256 quantity;
    }


    event eventDebug(string);
    event eventBalance(Balance[]);
    event eventTokenBalance(TokenBalance[]);


    function addToBalances(uint256[] memory tokenList__, address[] memory addressList__) external {
        require(tokenList__.length == addressList__.length, "length not consistent");
        
        for (uint256 i = 0; i < tokenList__.length; i++) {
            // update mapping
            _balances[tokenList__[i]][addressList__[i]] = _balances[tokenList__[i]][addressList__[i]] + 1;
            // update array for query
            if (token_array_index[tokenList__[i]] <= 0){
                token_array_index[tokenList__[i]] = token_array.length+1;
                token_array.push(tokenList__[i]);
            }
            if (user_array_index[addressList__[i]] <= 0){
                user_array_index[addressList__[i]] = user_array.length+1;
                user_array.push(addressList__[i]);
            }

        }
    }

    function getAllBalances() external view returns (TokenBalance[] memory)  {
        TokenBalance[] memory tokenBalance = new TokenBalance[](30);
        for (uint256 i = 0; i < token_array.length; i++) {
            Balance[] memory balance = new Balance[](100);
            for(uint256 j = 0; j < user_array.length; j++){
                balance[j] = (Balance(user_array[j], _balances[token_array[i]][user_array[j]]));
            }
            tokenBalance[i] = TokenBalance(token_array[i], balance);
        }

        return tokenBalance;
    }


    function getTokenArray() external view returns (uint256[] memory) {
        return token_array;
    }
    function getTokenArrayLength() external view returns (uint256){
        return token_array.length;
    }
    function getUserArray() external view returns (address[] memory) {
        return user_array;
    }
    function getUserArrayLength() external view returns (uint256){
        return user_array.length;
    }

}