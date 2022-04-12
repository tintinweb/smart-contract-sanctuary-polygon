// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./FxBaseChildTunnel.sol";
import "./Ownable.sol";



contract MyToken is ERC20, FxBaseChildTunnel, Ownable {


    //Keep track of the timestamp of when a holder last withdrew their rewards.
    mapping(address=> uint256) public lastUpdated;

    //Daily reward
     uint256 public constant dailyToken = 5;

     //Testing only
    address public testing123;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) ERC20("My Token", "AF") {
        //Tokens are stored in the smart contract
        //For now only 1000 tokens
        _mint(address(this), 1000 * 10 ** 18);
    }

    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory data) internal override { 
        (address from, bool action) = abi.decode(data, (address,bool));

        testing123 = from;

        action? processStake(from): processUnstake(from);

    }

    function earned(address _address) public view returns(uint256){
        //86400seconds -> 24hrs
        return ((dailyToken/86400 * 10 **18) * (block.timestamp - lastUpdated[_address]));
    }

    function processStake(address _address) internal {
        //Update the lastUpdated field
        lastUpdated[_address] = block.timestamp;
    }
    
    function processUnstake(address _address) internal {
        //Tokens will be withdrew to the address and update the lastUpdated field
        uint256 amount = earned(_address);
        lastUpdated[_address] = block.timestamp;
        transferFrom(address(this), _address, amount);
    }

    function totalBalance(address _address) public view returns(uint256) {
        return balanceOf(_address) + earned(_address);
    }




    //OWNER FUNCTIONS
    function mint(address _to, uint256 _amount) public onlyOwner{
        _mint(_to, _amount * 10 ** 18);
    }


    function burn(uint256 _amount) public onlyOwner{
        _burn(msg.sender, _amount);
    }

    function withdraw(address _address, uint256 amount) public onlyOwner {
        transferFrom(address(this), _address, amount);
    }


    //Allow the owners to airdrop the tokens from the contract
    function airdrop(address[] calldata _addresses, uint256[] calldata _amounts) public onlyOwner{
        require(_addresses.length == _amounts.length, "Number of wallet addresses and amounts doesn't match");
        for(uint256 counter = 0; counter< _addresses.length; counter++) {
            uint256 amount = _amounts[counter];
            transferFrom(address(this), _addresses[counter], amount);
        }
    }
}