// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./IToken.sol";

contract ERCFaucet {
    IToken public erc20Token;
    IToken public erc721Token;

    constructor(IToken _erc20Token, IToken _erc721Token) {
        erc20Token = _erc20Token;
        erc721Token = _erc721Token;
    }

    function drip(
        address _receiver,
        uint256 _erc20Amount,
        uint256 _erc721Amount
    ) external {
        require(_receiver != address(0), "address 0");
        require(_erc20Amount > 0 || _erc721Amount > 0, "invalid amounts");

        if (_erc20Amount > 0) erc20Token.mint(_receiver, _erc20Amount);
        if (_erc721Amount > 0) erc721Token.mint(_receiver, _erc721Amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IToken {
    function mint(address _to, uint256 _amount) external;
}