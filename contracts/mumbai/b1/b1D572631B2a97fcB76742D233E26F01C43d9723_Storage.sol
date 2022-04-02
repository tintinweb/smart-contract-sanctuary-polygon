// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Storage {
    address[] _allowedAddress = new address[](4);
    address[] swapAdapter = new address[](2);

    address ownerAddress;

    constructor() {
        _allowedAddress.push(0x79910e35c0d0D4758840F7Dbb4487C58506F5767);
        _allowedAddress.push(0x36615cBaB9Def10fEe9a992a45595517ee33243B);
        _allowedAddress.push(0xe2b9Fe279E07316dC235e64Eb4D255e710D5375a);
        swapAdapter.push(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        swapAdapter.push(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    }

    address public UniV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public router03 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public MATICMainnet = 0x0000000000000000000000000000000000001010;
    address public WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    function getAllowedAddress() public view returns (address[] memory) {
        return _allowedAddress;
    }

    function getSwapAdapter() public view returns (address[] memory) {
        return swapAdapter;
    }

    /**
    setting swap adapter, 0 for V2 , 1 for V3.
    */
    function setSwapAdapter(address _newSwapAdapter) public {
        require(ownerAddress == msg.sender, "not call by owner");
        swapAdapter.push(_newSwapAdapter);
    }

    function setAllowedAddress(address _newAddress) public {
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