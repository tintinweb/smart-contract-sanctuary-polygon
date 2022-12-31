/**
 *Submitted for verification at polygonscan.com on 2022-12-30
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


    event eventDebug(string msg);
    event eventUint256(uint256 num);
    event eventBalance(Balance[] balance);
    event eventTokenBalance(TokenBalance[] tokenBalance);


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
        TokenBalance[] memory tokenBalance = new TokenBalance[](token_array.length);
        for (uint256 i = 0; i < token_array.length; i++) {
            Balance[] memory balance = new Balance[](user_array.length);
            for(uint256 j = 0; j < user_array.length; j++){
                balance[j] = (Balance(user_array[j], _balances[token_array[i]][user_array[j]]));
            }
            tokenBalance[i] = TokenBalance(token_array[i], balance);
        }

        return tokenBalance;
    }
    function getAllBalances_testSize(uint256 a, uint256 b) external view returns (TokenBalance[] memory)  {
        TokenBalance[] memory tokenBalance = new TokenBalance[](a);
        for (uint256 i = 0; i < token_array.length; i++) {
            Balance[] memory balance = new Balance[](b);
            for(uint256 j = 0; j < user_array.length; j++){
                balance[j] = (Balance(user_array[j], _balances[token_array[i]][user_array[j]]));
            }
            tokenBalance[i] = TokenBalance(token_array[i], balance);
        }

        return tokenBalance;
    }
    function getAllBalances_pagination(uint256 token_offset, uint256 token_limit, uint256 user_offset, uint256 user_limit) external view returns (TokenBalance[] memory)  {
        
        uint256 tl = token_limit; 
        if (tl > token_array.length){
            tl = token_array.length;
        }
        uint256 ul = user_limit;
        if (ul > user_array.length){
            ul = user_array.length;
        }
        uint256 t_end = token_offset+token_limit;
        if (t_end > token_array.length){
            t_end = token_array.length;
        }
        uint256 u_end = user_offset+user_limit;
        if (u_end > user_array.length){
            u_end = user_array.length;
        }
        
        TokenBalance[] memory tokenBalance = new TokenBalance[](tl);
        for (uint256 i = 0; i < token_limit; i++) {
            uint256 i_offset = i+token_offset; // to avoid slack too deep problem

            Balance[] memory balance = new Balance[](ul);
            for(uint256 j = 0; j < user_limit; j++){
                uint256 j_offset = j+user_offset;
                balance[j] = (Balance(user_array[j_offset], _balances[token_array[i_offset]][user_array[j_offset]]));
            }
            tokenBalance[i] = TokenBalance(token_array[i_offset], balance);
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