// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Token.sol';
import './Tree.sol';
import './Status.sol';
import './Kyc.sol';

contract Marketing {

    address owner;
    Token token;
    Tree tree;
    Status status;
    Kyc kyc;
    uint[20][6] internal percents;

    constructor(
        address _token,
        address _tree,
        address _status,
        address _kyc,
        uint[20][6] memory _percents
    ){
        owner = msg.sender;
        token = Token(_token);
        tree = Tree(_tree);
        status = Status(_status);
        kyc = Kyc(_kyc);
        percents = _percents;
    }

    function distribute(uint256 _amount, address _distributor) public {
        require(token.balanceOf(msg.sender) >= _amount);
        require(token.allowance(msg.sender, address(this)) >= _amount);
        require(_amount > 0);

        address[] memory parents = tree.getElementParents(_distributor);
        uint256 sentAmount = 0;

        for (uint i = 0; i < parents.length; i++) {
            if (i > 19) {break;}
            if (parents[i] == address(0)) {break;}
            if (kyc.verified(parents[i]) == false) {continue;}

            uint256 levelStatus = status.status(parents[i]);
            uint256 tokensToSend = _amount * percents[levelStatus][i] / 10000;

            if (tokensToSend == 0) {continue;}

            assert(tokensToSend + sentAmount <= _amount);
            assert(token.transferFrom(msg.sender, parents[i], tokensToSend));

            sentAmount += tokensToSend;
        }

        assert(token.transferFrom(msg.sender, owner, _amount - sentAmount));
    }
}