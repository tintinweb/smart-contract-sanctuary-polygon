// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Storage  {
    address[] _allowedAddress = new address[](100);
    address[] swapAdapter = new address[](30);
    address ownerAddress;


    address public UniV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public router03 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address public MATICMainnet = 0x0000000000000000000000000000000000001010;
    address public WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;


    function getRouter03() public view returns (address) {
        return router03;
    }

    constructor()  {
    ownerAddress = msg.sender;
    }


    /**
    setting swap adapter, 0 for V2 , 1 for V3.
    */
    function setSwapAdapter(address _newSwapAdapter)  public {
       require(ownerAddress == msg.sender, "not call by owner");
        swapAdapter.push(_newSwapAdapter);
    }

    function setAllowedAddress(address _newAddress)  public {
        require(ownerAddress == msg.sender, "not call by owner");
        _allowedAddress.push(_newAddress);
    }

    function isAllowedAddress(address senderAddress)
        
        public
        view
        returns (bool status)
    {
        for (uint256 i = 0; i < _allowedAddress.length; i++) {
            if (_allowedAddress[i] == senderAddress) {
                status = true;
            }
        }
        status = false;
    }

 

}