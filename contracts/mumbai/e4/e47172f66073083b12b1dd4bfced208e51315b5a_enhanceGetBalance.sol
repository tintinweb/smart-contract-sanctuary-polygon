/**
 *Submitted for verification at polygonscan.com on 2023-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract enhanceGetBalance {
    
    mapping(uint256 => mapping(address => uint256)) public _balances;
    uint256[] public _token_array;
    mapping (uint256 => uint256) public _token_array_index;

    // address[] public _user_array;
    // mapping (address => uint256) public _user_array_index;

    mapping(uint256 => address[]) public _token_user_array;
    mapping(uint256 => mapping(address => uint256)) public _token_user_array_index;

    // for remove token from token_array
    // loop to check all address of token, if all address balance is 0, then remove token from token_array
    
    // for remove address from _token_user_array
    // if address balance of token is 0, then remove address from _token_user_array
    

    


    // Balance[] public balanceList;
    struct TokenBalance{
        uint256 token_id;
        Balance[] balance;
    }
    struct Balance {
        address user;
        uint256 quantity;
    }


    // event eventDebug(string msg);
    // event eventUint256(uint256 num);
    // event eventBalance(Balance[] balance);
    // event eventTokenBalance(TokenBalance[] tokenBalance);


    function addToBalances(uint256[] memory tokenList_, address[] memory addressList_) external {
        require(tokenList_.length == addressList_.length, "list length not consistent");
        
        for (uint256 i = 0; i < tokenList_.length; i++) {
            // update mapping
            _balances[tokenList_[i]][addressList_[i]] = _balances[tokenList_[i]][addressList_[i]] + 1;
            // update array for query
            if (_token_array_index[tokenList_[i]] == 0){
                _token_array_index[tokenList_[i]] = _token_array.length+1;
                _token_array.push(tokenList_[i]);
            }
            if (_token_user_array_index[tokenList_[i]][addressList_[i]] == 0){
                _token_user_array_index[tokenList_[i]][addressList_[i]] = _token_user_array[tokenList_[i]].length+1;
                _token_user_array[tokenList_[i]].push(addressList_[i]);
            }

        }
    }

    function transfer(address from, address to, uint256 id, uint256 amount) external {
        require(_balances[id][from] >= amount, "Insufficient balance");
        _balances[id][from] -= amount;
        _balances[id][to] += amount;
        if (_balances[id][from] == 0){
            remove_from_user_array(id, from);
        }
        if (_balances[id][to] == amount){
            _token_user_array_index[id][to] = _token_user_array[id].length+1;
            _token_user_array[id].push(to);
        }
    }


    function remove_from_token_array(uint256 id) public {
        uint256 i = _token_array_index[id]-1; 
        require(i >= 0, "target item not found"); // if exist, res should >= 0
        _token_array_index[_token_array[_token_array.length-1]] = _token_array_index[id]; // replace the last item to the slot of removed item
        _token_array_index[id] = 0; // clean 
        _token_array[i] = _token_array[_token_array.length-1]; // replace the last item to the slot of removed item
        _token_array.pop();
    }

    function remove_from_user_array(uint256 tokenId, address user) public {
        uint256 i = _token_user_array_index[tokenId][user]-1; 
        require(i >= 0, "target item not found"); // if exist, res should >= 0 
        _token_user_array_index[tokenId][_token_user_array[tokenId][_token_user_array[tokenId].length-1]] = _token_user_array_index[tokenId][user]; // replace the last item to the slot of removed item
        _token_user_array_index[tokenId][user] = 0; // clean 
        _token_user_array[tokenId][i] = _token_user_array[tokenId][_token_user_array[tokenId].length-1]; // replace the last item to the slot of removed item
        _token_user_array[tokenId].pop();
    }
    



    function getAllBalances() external view returns (TokenBalance[] memory)  {
        TokenBalance[] memory tokenBalance = new TokenBalance[](_token_array.length);
        for (uint256 i = 0; i < _token_array.length; i++) {
            Balance[] memory balance = new Balance[](_token_user_array[_token_array[i]].length);
            for(uint256 j = 0; j < _token_user_array[_token_array[i]].length; j++){
                balance[j] = (Balance(_token_user_array[_token_array[i]][j], _balances[_token_array[i]][_token_user_array[_token_array[i]][j]]));
            }
            tokenBalance[i] = TokenBalance(_token_array[i], balance);
        }

        return tokenBalance;
    }
    function getAllBalances_testSize(uint256 a, uint256 b) external view returns (TokenBalance[] memory)  {
        TokenBalance[] memory tokenBalance = new TokenBalance[](a);
        for (uint256 i = 0; i < _token_array.length; i++) {
            Balance[] memory balance = new Balance[](b);
            for(uint256 j = 0; j < _token_user_array[_token_array[i]].length; j++){
                balance[j] = (Balance(_token_user_array[_token_array[i]][j], _balances[_token_array[i]][_token_user_array[_token_array[i]][j]]));
            }
            tokenBalance[i] = TokenBalance(_token_array[i], balance);
        }

        return tokenBalance;
    }
    function getAllBalances_pagination(uint256 token_limit, uint256 token_offset, uint256 user_limit, uint256 user_offset) external view returns (TokenBalance[] memory)  {
        
        require(token_offset>=0, "token_offset out of bounds");
        require(token_offset<_token_array.length, "token_offset out of bounds");
        require(user_offset>=0, "user_offset out of bounds");
        // require(user_offset<_user_array.length, "user_offset out of bounds");

        uint256 tl = token_limit; 
        if (tl + token_offset > _token_array.length){
            tl = _token_array.length - token_offset;
        }
        uint256 ul = user_limit;

        
        TokenBalance[] memory tokenBalance = new TokenBalance[](tl);
        for (uint256 i = 0; i < tl; i++) {
            uint256 i_offset = i + token_offset; 
            // if (i_offset > _token_array.length){
            //     break;
            // }

            Balance[] memory balance = new Balance[](ul);
            ul = user_limit;
            if (ul + user_offset > _token_user_array[_token_array[i]].length){
                ul = _token_user_array[_token_array[i]].length - user_offset;
            }

            for(uint256 j = 0; j < ul; j++){
                uint256 j_offset = j + user_offset;
                if (j_offset > _token_user_array[_token_array[i]].length){
                    break;
                }
                balance[j] = (Balance(_token_user_array[_token_array[i]][j_offset], _balances[_token_array[i_offset]][_token_user_array[_token_array[i]][j_offset]]));
            }
            tokenBalance[i] = TokenBalance(_token_array[i_offset], balance);
        }

        return tokenBalance;
    }



    function getTokenArray() external view returns (uint256[] memory) {
        return _token_array;
    }
    function getTokenArrayLength() external view returns (uint256){
        return _token_array.length;
    }
    // function getUserArray() external view returns (address[] memory) {
    //     return _token_user_array;
    // }
    // function getUserArrayLength() external view returns (uint256){
    //     return _token_user_array.length;
    // }
    function getUserArray_ofToken(uint256 tokenId) external view returns (address[] memory) {
        return _token_user_array[tokenId];
    }
    function getUserArrayLength_ofToken(uint256 tokenId) external view returns (uint256){
        return _token_user_array[tokenId].length;
    }
    

}