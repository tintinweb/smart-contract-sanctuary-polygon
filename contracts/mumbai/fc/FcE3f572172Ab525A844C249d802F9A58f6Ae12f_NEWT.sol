// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity >=0.6.0 <0.9.0;

import "./ERC20.sol";

contract NEWT is ERC20

{
    constructor() ERC20 ("NEWT" , "NT" , 1000000 , 5){
        _balances[_msgSender()] = 1000000 ;
    }
}