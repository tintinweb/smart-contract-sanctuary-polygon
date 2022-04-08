// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Storage {
    address[] dest_address = new address[](4);
    address[] swapAdapter = new address[](2);
    address ownerAddress;
    uint[] shares = [3,2,1];
    constructor() {
        // 1: Marketing 2. dev  3. charity 4. Rusticity
        dest_address.push(0x36615cBaB9Def10fEe9a992a45595517ee33243B);
        dest_address.push(0x79910e35c0d0D4758840F7Dbb4487C58506F5767);
        dest_address.push(0xe2b9Fe279E07316dC235e64Eb4D255e710D5375a);
        dest_address.push(0xAec3F27c1612dF71075417007341040b2c6Dd561);
        swapAdapter.push(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        swapAdapter.push(0x1256aBd582D90550aa267d23F2B271328dA7d90d);
        ownerAddress = msg.sender;
    }

    address public UniV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public router03 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public MATICMainnet = 0x0000000000000000000000000000000000001010;
    address public WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    function getAllowedAddress() public view returns (address[] memory) {
        return dest_address;
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
        dest_address.push(_newAddress);
    }

    function isAllowedAddress(address senderAddress)
        public
        view
        returns (bool)
    {
        bool status = false;

        for (uint256 i = 0; i < dest_address.length; i++) {
            if (dest_address[i] == senderAddress) {
               return true;
            }
        }
        return status;
    
    }

}