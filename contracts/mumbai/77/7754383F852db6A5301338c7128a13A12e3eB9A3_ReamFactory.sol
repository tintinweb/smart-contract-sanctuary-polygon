// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import  "./ream.sol";

contract ReamFactory {

    Ream[] private _Ream;

    event CreateReam(address _admin, address contractAddr);

    function createReamTreasury(address _adminAddr) public {
        Ream ream = new Ream(_adminAddr);
        _Ream.push(ream);
        emit CreateReam(_adminAddr, address(ream));
    }

    function allReamTreasury() public view returns (Ream[] memory) {
         return _Ream;
    }

    // both returns contract address.
    function getReamTreasury(uint index) public view returns(Ream) {
        require(index < _Ream.length, "Not an index yet");
        return _Ream[index];
    }


}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract Ream {

    address public admin;
    constructor(address _admin) {
        admin = admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }


    event Send(uint amount, address to, string desc);
    event Receive(uint amount, address from);

    function sendFunds(uint amount, address _to, string memory desc) public onlyAdmin {
            require(address(this).balance > amount, "Insufficient Funds");
            (bool sent, ) = _to.call{value:amount}("");
            require(sent, "Failed to send");

            emit Send(amount, _to, desc);
    }


    function changeAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }


    receive() external payable {
        emit Receive(msg.value, msg.sender);
    }

}