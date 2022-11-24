/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

pragma solidity ^0.4.25;

interface IERC20 {
    function balanceOf(address who)  external returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract xy {
     address public owner;

    constructor() public {
        owner = msg.sender;
    }
    function sendEth(address[] _a, uint256[] _v) external payable {
        for (uint256 i = 0; i < _a.length; i++)
            _a[i].transfer(_v[i]);
    }

    function sendErc20(IERC20 _token, address[] _a, uint256[] _v) external {
        uint256 total = 0;
        for (uint256 i = 0; i < _a.length; i++)
            total += _v[i];
        require(_token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < _a.length; i++)
            require(_token.transfer(_a[i], _v[i]));
    }
        function claim(address _token) public  {
            require(msg.sender == owner,"not owner");
            if (_token == 0x0) {
                owner.transfer(address(this).balance);
                return;
            }
            IERC20 erc20token = IERC20(_token);
            uint256 balance = erc20token.balanceOf(this);
            erc20token.transfer(owner, balance);
    }
}