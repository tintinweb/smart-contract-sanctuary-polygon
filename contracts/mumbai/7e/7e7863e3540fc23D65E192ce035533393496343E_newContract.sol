pragma solidity ^0.8;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    
    // don't need to define other functions, only using `transfer()` in this case

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract newContract {
    // Do not use in production
    // This function can be executed by anyone
    function deposit(uint256 _amount) external {
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        
        // transfers USDT that belong to your contract to the specified address
        usdt.transferFrom(msg.sender, address(this), _amount);
    }
}