/**
 *Submitted for verification at polygonscan.com on 2022-02-11
*/

// SPDX-License-Identifier: MIT
/*
M 0x74d0De43d1aAb05137ec27e196B212f77bC6ff68
*/

pragma solidity ^0.8.0;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface MainCon {
    function coinBalances(address) external view returns (uint256);
    function stage() external view returns (uint256);
    function tIdToHash(uint) external view returns(uint);
    function tokenContent(uint) external view returns(uint);
    function _owners(uint) external view returns(address);
    function wlOwners(uint) external view returns(address);
    function wLength() external view returns(uint);
    function mintWL(address[] calldata aa) external;
    function withDraw(address user, uint amount) external;
    function refundEmpty(uint t) external;
    function deposit(address sender, address recipient, uint amount) external;
    function debugStage(uint n) external;
}

contract RusPackProxy {
    address public auctor;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public mainCon;

    address[] public operators;
    mapping (address => uint256) public operIx; // (iX+1)! modOperator - done
    
    function balance(address a) external view returns(uint) { return MainCon(mainCon).coinBalances(a); }
    function stage() external view returns(uint) { return MainCon(mainCon).stage(); }
    function tIdToHash(uint t) external view returns(uint) { return MainCon(mainCon).tIdToHash(t); }
    function tokenContent(uint t) external view returns(uint) { return MainCon(mainCon).tokenContent(t); }
    function getOwnersList(uint s, uint e) external view returns(address[] memory) {
        uint n = e - s + 1;
        require( n <= 10000 );
        address[] memory users = new address[]( n );
        for(uint k = s; k <= e; k++)
            users[k] = MainCon(mainCon)._owners(k);
        return users;
    }
    function getWlOwnersList(uint s, uint e) external view returns(address[] memory) {
        uint n = e - s + 1;
        require( n <= 10000 );
        address[] memory users = new address[](n);
        for(uint k = s; k <= e; k++)
            users[k] = MainCon(mainCon).wlOwners(k);
        return users;
    }
    function wLength() external view returns(uint) { return MainCon(mainCon).wLength(); }
    function mintWL(address[] calldata aa) external { MainCon(mainCon).mintWL(aa); }
    function withDraw(address user, uint amount) external { MainCon(mainCon).withDraw(user, amount); }
    function refundEmpty(uint t) external { MainCon(mainCon).refundEmpty(t); }
    function deposit(address sender, address recipient, uint amount) external {
        MainCon(mainCon).deposit(sender, recipient, amount);
    }
    function debugStage(uint n) external { MainCon(mainCon).debugStage(n); }
    
    constructor() {
        auctor = msg.sender;
        modOperator(0xCD8F684144402bAB30C3BCE7E390103A28f03D30, true); // Vlad
        modOperator(0xFd0D8EE50Be6F15E26b3A49BC4A19134dA7E25f7, true); // Kirill
    }
    
    function setPack(address con) external {
        require( msg.sender == auctor );
        mainCon = con;
    }
    
    function contractBalance() external view returns(uint) {
        return IERC20(usdc).balanceOf( address(this) );
    }
    
    function withDraw(address coin, address whom, uint amount) external {
        require( msg.sender == auctor );
        if(coin == address(0) )
            coin = usdc;
        IERC20(coin).transfer(whom, amount);
    }

    function modOperator(address op, bool state) public {
        require( msg.sender == auctor || operIx[msg.sender] > 0 );
        if(state) { // setOp
            if( operIx[op] == 0 ) {
                operators.push(op);
                operIx[op] = operators.length;
            }
        }
        else { // resetOp
            if( operIx[op] > 0 ) {
                delete operators[ operIx[op] - 1 ];
                delete operIx[op];
            }
        }
    }

}